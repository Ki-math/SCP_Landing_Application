function [cmd,sol,info] = trackStep(x,t,plan,cfg,opt,warm)
%TRACKSTEP  計画軌道を追従する短水平 MPC を1回解き, 姿勢/推力指令を返す.
%
%   [CMD,SOL,INFO] = TRACKSTEP(X,T,PLAN,CFG,OPT) は時刻 T の状態 X から
%   PLAN を追従する凸QPを解く. 外部ソルバに依存せず, PIPG のみで求解する.
%
%   入力
%     X    : [rx; ry; vx; vy; theta; omega; m]  現在状態 (物理単位)
%     T    : 現在時刻 [s]
%     PLAN : 軌道計画の解 (scpk.plan / scp6Continuation の出力)
%     CFG  : model が返すモデル定数
%     OPT  : trackOptions が返す設定
%     WARM : 前回の SOL (省略可, 線形化点とソルバの初期値に使う)
%
%   出力
%     CMD  : struct('theta','omega','alpha','thrust','nEng','df')  内ループへの指令
%     SOL  : 予測軌道 (x,u,g) と参照 (xr) — 物理/モデル無次元単位
%     INFO : iters, primal, condP, time
%
%   See also SCPK.BUILDTRACK, SCPK.SOLVEQP, SCPK.PRECONDITION
if nargin < 5 || isempty(opt), opt = scpk.trackOptions(); end
if nargin < 6, warm = []; end
tic;
sc = cfg.sc; nx = 7; nu = 3; N = opt.Nm; dt = opt.dtm/sc.T;
sx = [sc.L; sc.L; sc.V; sc.V; 1; 1/sc.T; cfg.m0];
x0 = x(:)./sx;

%% --- 参照を水平上でサンプル ---
tk = min(t + (0:N)*opt.dtm, plan.t(end));
xr = zeros(nx,N+1);
xr(1,:) = interp1(plan.t, plan.h,     tk,'linear')/sc.L;
xr(2,:) = interp1(plan.t, plan.y,     tk,'linear')/sc.L;
xr(3,:) = interp1(plan.t, plan.vh,    tk,'linear')/sc.V;
xr(4,:) = interp1(plan.t, plan.vy,    tk,'linear')/sc.V;
xr(5,:) = interp1(plan.t, plan.theta, tk,'linear');
xr(6,:) = interp1(plan.t, plan.omega, tk,'linear')*sc.T;
xr(7,:) = interp1(plan.t, plan.m,     tk,'linear')/cfg.m0;
nuP = size(plan.uhat,2);  tu = plan.t(1:nuP);  tm = min(tk(1:N), tu(end));
ur = zeros(nu,N);
for i = 1:nu, ur(i,:) = interp1(tu, plan.uhat(i,:), tm,'linear'); end
gr  = reshape(interp1(tu, plan.ghat, tm,'linear'),1,N);
eng = round(interp1(tu, plan.engSched(:).', tm,'previous','extrap'));
eng = max(1, min(3, eng));

%% --- SCP 反復 (線形化点を更新) ---
xl = xr; ul = ur; gl = gr;  z0 = [];
if ~isempty(warm) && isfield(warm,'x')
    xl = warm.x; ul = warm.u; gl = warm.g;
end
xl(:,1) = x0;
qpStat = repmat({''},1,opt.scpIter);  ok = true;  vc = inf;
for it = 1:opt.scpIter
    [prob,ix,D] = scpk.buildTrack(x0,xr,ur,gr,eng,dt,cfg,opt,xl,ul,gl);
    [probS,S]   = scpk.precondition(prob);
    [zh,qi]     = scpk.solveQP(probS, opt.qp, z0);
    qpStat{it} = qi.status;
    z  = S.col .* zh;  z0 = zh;
    xs = reshape(z(ix.x(:)),nx,N+1) .* D.x;
    us = reshape(z(ix.u(:)),nu,N)   .* D.u;
    gs = reshape(z(ix.g),1,N)       .* D.g;
    vc = sum(max(0,z(ix.vp(:)))) + sum(max(0,z(ix.vm(:))));
    xl = xs; ul = us; gl = gs;
end

%% --- 受け入れ判定とフォールバック ---
%% QP が異常なら前回解を1ステップずらして使う (受動フォールバック).
%% それも無ければ姿勢保持 + 現在推力維持という安全既定値に落ちる.
bad = ~all(strcmp(qpStat,'converged') | strcmp(qpStat,'maxIter'));
%% 仮想制御が残っていれば線形化された動力学すら満たせていない.
%% QP 自体は ν で必ず解けるので, primalInfeasible は正常時に出ない.
%% 追従MPC で見るべきはステータスではなく ν の残存量.
bad = bad || (vc > opt.maxVirtCtrl);
if bad || any(~isfinite(xs(:))) || any(~isfinite(us(:)))
    ok = false;
    if ~isempty(warm) && isfield(warm,'x') && size(warm.x,2) >= 3
        xs = [warm.x(:,2:end), warm.x(:,end)];       %% 1ステップシフト
        us = [warm.u(:,2:end), warm.u(:,end)];
        gs = [warm.g(:,2:end), warm.g(:,end)];
    else
        xs = repmat(x0,1,N+1);  xs(:,1) = x0;         %% 姿勢保持
        us = repmat([hypot(x0(1),0)*0 + cfg.Tmin; 0; 0],1,N);
        gs = cfg.Tmin*ones(1,N);
    end
end

%% --- 内ループへの指令 ---
cmd.theta  = xs(5,2);
cmd.omega  = xs(6,2)/sc.T;
cmd.alpha  = (xs(6,3)-xs(6,2))/(dt*sc.T^2);
cmd.thrust = hypot(us(1,1),us(2,1))*cfg.Fs;
cmd.nEng   = eng(1);
cmd.df     = us(3,1);
sol.x = xs; sol.u = us; sol.g = gs; sol.xr = xr; sol.tk = tk;
info.iters  = qi.iters;  info.primal = qi.primal;
info.time   = toc;
info.trackErr = (xs(:,1)-xr(:,1)).*sx;
info.qpStatus = qpStat;  info.ok = ok;  info.virtCtrl = vc;
end


