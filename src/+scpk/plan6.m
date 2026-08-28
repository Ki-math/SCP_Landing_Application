function [sol,info] = plan6(x0phys,xTphys,tf,cfg,opt,ref)
%PLAN6  6自由度 動力降下軌道を逐次凸計画 (SCvx) で解く.
%
%   [SOL,INFO] = PLAN6(X0PHYS,XTPHYS,TF,CFG,OPT,REF)
%
%   X0PHYS = [r_I(3); v_B(3); q(4); w_B(3); m]  初期状態 (物理単位, 質量は kg)
%   XTPHYS = 同じ並びの終端目標 (無次元, 内部で使うのは 12 成分)
%   TF     = 区間時間 [s]
%   REF    = ウォームスタート用の前回解 (省略可)
%
%   四元数の単位ノルム制約は非凸なので課さない. 各反復で線形化点を正規化して
%   近似的に保つ (Szmuk & Acikmese の 6-DoF SCvx と同じ方式).
%
%   OPT.engSched に基数スケジュール (1xN) を与える. 省略時は全区間 cfg.nEng.
%
%   See also SCPK.BUILDPLAN6, SCPK.DYNAMICS6, SCPK.SOLVEQP
if nargin < 5 || isempty(opt), opt = scpk.planOptions6(); end
if nargin < 6, ref = []; end
sc = cfg.sc;  nx = 14;  nu = 7;
sx = [repmat(sc.L,3,1); repmat(sc.V,3,1); ones(4,1); repmat(1/sc.T,3,1); cfg.m0];
x0 = x0phys(:)./sx;
xT = xTphys(:);
%% tf はスカラー (一様刻み) または [tf1 tf2 ...] のセグメント指定.
%% セグメント指定のときは opt.nSeg で各セグメントの節点数を与える.
%% 降下と着陸で時間スケールが 10 倍違うので, 一様刻みでは節点が足りない.
if isscalar(tf)
    N = opt.N;  dt = (tf/sc.T)/N;  tGrid = (0:N)*dt*sc.T;
else
    nSeg = opt.nSeg;  N = sum(nSeg);  dt = zeros(1,N);  tGrid = zeros(1,N+1);  p = 0;  tAcc = 0;
    for s = 1:numel(tf)
        d = (tf(s)/sc.T)/nSeg(s);
        dt(p+(1:nSeg(s))) = d;
        tGrid(p+(1:nSeg(s))+1) = tAcc + (1:nSeg(s))*d*sc.T;
        p = p + nSeg(s);  tAcc = tAcc + tf(s);
    end
end
if isfield(opt,'engSched') && ~isempty(opt.engSched), eng = opt.engSched;
else, eng = cfg.nEng*ones(1,N); end

%% --- 初期線形化点 ---
if ~isempty(ref)
    so = linspace(0,1,size(ref.xhat,2)).';  sn = linspace(0,1,N+1).';
    xl = interp1(so, ref.xhat.', sn,'linear','extrap').';
    su = linspace(0,1,size(ref.uhat,2)).';  sm = linspace(0,1,N).';
    ul = interp1(su, ref.uhat.', sm,'linear','extrap').';
    if size(ul,1) ~= nu, ul = ul.'; end
    gl = reshape(interp1(su, ref.ghat.', sm,'linear','extrap'),1,N);
else
    xl = zeros(nx,N+1);
    %% xT は終端目標 12 成分: [位置3; 速度3; 四元数ベクトル部3; 角速度3]
    %% 状態の並び (14) とは対応が違うので明示的に写す
    iState = [1 2 3, 4 5 6, 8 9 10, 11 12 13];   %% xT に対応する状態インデックス
    for j = 1:12
        xl(iState(j),:) = linspace(x0(iState(j)), xT(j), N+1);
    end
    xl(14,:) = linspace(x0(14), x0(14)*0.93, N+1);
    %% 四元数はベリーから垂直へ球面線形補間
    for k = 0:N
        s = k/N;
        xl(7:10,k+1) = slerpLocal(x0(7:10), [1;0;0;0], s);
    end
    ul = repmat([cfg.Tmin;0;0;0;0;0;0],1,N);  gl = cfg.Tmin*ones(1,N);
end
xl(:,1) = x0;

info = struct('iters',zeros(1,opt.maxIter),'primal',zeros(1,opt.maxIter), ...
              'step',zeros(1,opt.maxIter),'virtCtrl',zeros(1,opt.maxIter), ...
              'nIter',0,'time',0);
info.qpStatus = repmat({''},1,opt.maxIter);
info.rho = nan(1,opt.maxIter);  info.wTR = nan(1,opt.maxIter);
tic;  z0 = [];
wTR = opt.wTR;  Jprev = inf;  xPrev = xl;  uPrev = ul;  gPrev = gl;
optI = opt;
%% defect 評価用のスケール (許容誤差ベース). 状態の単位差を吸収する
optI.dScale = [repmat(opt.tol.pos/sc.L,3,1); repmat(opt.tol.vel/sc.V,3,1); ...
              repmat(opt.tol.quat,4,1); repmat(deg2rad(opt.tol.rate)*sc.T,3,1); ...
              opt.tol.mass/cfg.m0];
for it = 1:opt.maxIter
    optI.wTR = wTR;
    [prob,ix,D] = scpk.buildPlan6(x0,xT,xl,ul,gl,eng,dt,cfg,optI);
    [probS,S]   = scpk.precondition(prob);
    [zh,qi]     = scpk.solveQP(probS, opt.qp, z0);
    z  = S.col .* zh;  z0 = zh;
    xs = reshape(z(ix.x(:)),nx,N+1) .* D.x;
    us = reshape(z(ix.u(:)),nu,N)   .* D.u;
    gs = reshape(z(ix.g),1,N)       .* D.g;
    %% 四元数を正規化してから次の線形化点にする (単位ノルムを近似的に保つ)
    for k = 1:N+1
        nq = norm(xs(7:10,k));
        if nq > eps, xs(7:10,k) = xs(7:10,k)/nq; end
    end
    step = max(max(abs(xs - xl)./D.x));
    %% --- 信頼領域の適応制御 ---
    %% 予測改善量は部分問題のスラック (nu, e) から, 実際の改善量は真の非線形
    %% 伝播から測る. 比 rho が小さいほど線形化が当てにならない.
    if opt.adaptTR
        vcNow = sum(max(0,z(ix.vp(:)))) + sum(max(0,z(ix.vm(:))));
        eNow  = sum(max(0,z(ix.ep))) + sum(max(0,z(ix.em)));
        Jpred = -opt.wFuel*xs(14,N+1)/optI.dScale(14) + opt.lamVC*vcNow + opt.lamTerm*eNow;
        Jact  = scpk.penalizedCost(xs,us,xT,cfg,optI,dt);
        if ~isfinite(Jprev)
            Jprev = scpk.penalizedCost(xl,ul,xT,cfg,optI,dt);
        end
        dAct  = Jprev - Jact;
        dPred = Jprev - Jpred;
        if abs(dPred) < 1e-12, rho = 1; else, rho = dAct/dPred; end
        if rho < opt.rho0
            wTR = min(opt.wTRmax, wTR*opt.trShrink);   %% 棄却
            xs = xPrev;  us = uPrev;  gs = gPrev;
            info.rho(it) = rho;  info.wTR(it) = wTR;  info.nIter = it;
            if opt.verbose
                fprintf('  it %2d: 棄却 rho=%6.3f -> wTR=%.3f\n', it, rho, wTR);
            end
            xl = xs;  ul = us;  gl = gs;
            continue
        elseif rho < opt.rho1
            wTR = min(opt.wTRmax, wTR*opt.trShrink);
        elseif rho > opt.rho2
            wTR = max(opt.wTRmin, wTR*opt.trExpand);
        end
        Jprev = Jact;  info.rho(it) = rho;  info.wTR(it) = wTR;
    end
    xPrev = xs;  uPrev = us;  gPrev = gs;
    xl = xs;  ul = us;  gl = gs;
    info.iters(it)=qi.iters; info.primal(it)=qi.primal; info.step(it)=step; info.nIter=it;
    info.qpStatus{it} = qi.status;
    info.virtCtrl(it) = sum(max(0,z(ix.vp(:)))) + sum(max(0,z(ix.vm(:))));
    if opt.verbose
        fprintf('  it %2d: step=%9.3e nu=%9.3e rho=%6.3f wTR=%6.2f (%s)\n', ...
                it, step, info.virtCtrl(it), info.rho(it), wTR, qi.status);
    end
    if step < opt.tolStep, break; end
end
info.time = toc;

%% --- 物理単位へ ---
sol.t  = tGrid;
sol.r  = xs(1:3,:)*sc.L;   sol.v = xs(4:6,:)*sc.V;
sol.q  = xs(7:10,:);       sol.w = xs(11:13,:)/sc.T;
sol.m  = xs(14,:)*cfg.m0;
sol.xhat = xs;  sol.uhat = us;  sol.ghat = gs;
sol.T_B  = us(1:3,:)*cfg.Fs;   sol.flap = us(4:7,:);
sol.Tmag = vecnorm(sol.T_B);
sol.throttle = sol.Tmag./(eng*cfg.veh.thrustPerEng);
sol.engSched = eng;  sol.tf = tf;  sol.dt = dt*sc.T;
sol.propellant = sol.m(1) - sol.m(end);
sol.qpStatus = info.qpStatus(1:info.nIter);
sol.virtCtrl = info.virtCtrl(info.nIter);
end


function q = slerpLocal(q1,q2,s)
%SLERPLOCAL  四元数の球面線形補間.
d = q1.'*q2;
if d < 0, q2 = -q2; d = -d; end
if d > 0.9995
    q = q1 + s*(q2-q1);
else
    th = acos(d);
    q = (sin((1-s)*th)*q1 + sin(s*th)*q2)/sin(th);
end
q = q/norm(q);
end



