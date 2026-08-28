function [u0,dbg,z0] = track6Step(xcPhys, tNow, ref, cfg, topt, z0)
%TRACK6STEP  参照軌道まわりのLTV追従MPCを1周期ぶん解く (100 ms 周期想定).
%
%   [U0,DBG,Z0] = TRACK6STEP(XCPHYS,TNOW,REF,CFG,TOPT,Z0)
%
%   XCPHYS 現在状態 (物理単位 14: [r_I(3); v_B(3); q(4); w_B(3); m(kg)])
%   TNOW   現在時刻 [s] (参照軌道の時間軸)
%   REF    計画解 (plan6ft の sol: t, xhat, uhat, engSched, phase)
%   Z0     前周期の解 (ウォームスタート, 空可)
%
%   偏差座標 dx = x - xr, du = u - ur を許容誤差でスケールし, 等式は参照に
%   沿ったLTV離散化, 箱は物理制約から参照を引いたもの. 凸QPを PIPG で1回
%   解くだけ (real-time iteration; SCP反復なし).
%
%   U0  適用する制御 (無次元 [T_B(3); flap(4)])
%   DBG 診断 (qp status/iters/time, 参照インデックス)
%
%   See also SCPK.TRACK6OPTIONS, SCPK.SOLVEQP, SCPK.DYNAMICS6
sc = cfg.sc;  nx = 14;  nu = 7;
H = topt.H;  dtau = topt.dt/sc.T;
sx = [repmat(sc.L,3,1); repmat(sc.V,3,1); ones(4,1); repmat(1/sc.T,3,1); cfg.m0];
xc = xcPhys(:)./sx;

%% --- 参照のサンプル (ホライズン上) ---
tk = tNow + (0:H)*topt.dt;
tk = min(tk, ref.t(end));
xr = interp1(ref.t, ref.xhat.', tk, 'linear', 'extrap').';     % 14 x H+1
tu = ref.t(1:size(ref.uhat,2));
ur = interp1(tu, ref.uhat.', tk(1:H), 'previous', 'extrap').'; % 7 x H
if size(ur,1) ~= nu, ur = ur.'; end
for k = 1:H+1
    nq = norm(xr(7:10,k)); if nq > eps, xr(7:10,k) = xr(7:10,k)/nq; end
end
engk = interp1(tu, ref.engSched(:), tk(1:H), 'previous', 'extrap').';

%% --- スケール ---
t = topt.tol;
Dx = [repmat(t.pos/sc.L,3,1); repmat(t.vel/sc.V,3,1); repmat(t.quat,4,1); ...
      repmat(deg2rad(t.rate)*sc.T,3,1); t.mass/cfg.m0];
Du = [repmat(t.thr/cfg.Fs,3,1); repmat(t.flap,4,1)];
wx = [repmat(topt.wPos,3,1); repmat(topt.wVel,3,1); repmat(topt.wQuat,4,1); ...
      repmat(topt.wRate,3,1); topt.wMass];

%% --- 変数: z = [zx_1..zx_H ; zu_0..zu_{H-1}] (スケール済み偏差) ---
ix = reshape(1:nx*H, nx, H);
iu = nx*H + reshape(1:nu*H, nu, H);
nz = nx*H + nu*H;

P = spdiags([repmat(wx,H,1); repmat(topt.rCtrl*ones(nu,1),H,1)], 0, nz, nz);
P(ix(:,H), ix(:,H)) = P(ix(:,H), ix(:,H)) * topt.wTerm;
P = P + topt.reg*speye(nz);
q = zeros(nz,1);

%% --- 等式: LTV離散化 dx_{k+1} = Ad dx_k + Bd du_k + d_k ---
G = spalloc(nx*H, nz, nx*H*(2*nx+nu));  g = zeros(nx*H,1);
dxc = (xc - xr(:,1))./Dx;                       %% 現在偏差 (スケール済み)
%% 線形化+離散化: 計画と同じ linDisc6All を σ=1 で流用 (MEXがあれば高速).
%% x' = A x + B u + f + c0 は sigma列=f の扱いで cd_eff = Sd*1 + cd と等価.
if exist('linDisc6All_mex','file') == 3
    [AdA,BdA,SdA,cdA] = linDisc6All_mex(xr(:,1:H+1), ur, 1, ones(1,H), dtau*ones(1,H), cfg);
else
    [AdA,BdA,SdA,cdA] = scpk.linDisc6All(xr(:,1:H+1), ur, 1, ones(1,H), dtau*ones(1,H), cfg);
end
for k = 1:H
    Ad = AdA(:,:,k);  Bd = BdA(:,:,k);  cd = SdA(:,k) + cdA(:,k);
    dk = (Ad*xr(:,k) + Bd*ur(:,k) + cd - xr(:,k+1))./Dx;   %% 参照の離散化残差
    r = nx*(k-1)+(1:nx);
    G(r, ix(:,k)) = speye(nx);
    if k == 1
        g(r) = diag(1./Dx)*Ad*diag(Dx)*dxc + dk;
    else
        G(r, ix(:,k-1)) = -diag(1./Dx)*Ad*diag(Dx);
        g(r) = dk;
    end
    G(r, iu(:,k)) = -diag(1./Dx)*Bd*diag(Du);
end

%% --- 箱: 物理制約 - 参照 ---
lb = -inf(nz,1);  ub = inf(nz,1);
for k = 1:H
    Tmax = engk(k)*cfg.Tmax1;
    Tmin = engk(k)*cfg.Tmin1;      %% 実機は最低スロットル 40% を下回れない
    %% 推力成分の箱 (Tmin <= T1 <= Tmax, |T2|,|T3| <= Tmax*sin(gimbal))
    lb(iu(1,k)) = (Tmin - ur(1,k))/Du(1);   ub(iu(1,k)) = (Tmax - ur(1,k))/Du(1);
    Tlat = Tmax*sin(cfg.veh.tvcMax);
    lb(iu(2,k)) = (-Tlat - ur(2,k))/Du(2);  ub(iu(2,k)) = (Tlat - ur(2,k))/Du(2);
    lb(iu(3,k)) = (-Tlat - ur(3,k))/Du(3);  ub(iu(3,k)) = (Tlat - ur(3,k))/Du(3);
    for i = 4:7
        lb(iu(i,k)) = (-cfg.veh.flapTrim - ur(i,k))/Du(i);
        ub(iu(i,k)) = ((cfg.veh.flapMax-cfg.veh.flapTrim) - ur(i,k))/Du(i);
    end
    if engk(k) == 0
        lb(iu(1:3,k)) = (0 - ur(1:3,k))./Du(1:3);
        ub(iu(1:3,k)) = (0 - ur(1:3,k))./Du(1:3);
    end
end

prob = struct('P',P,'q',q,'G',G,'g',g,'A',sparse(0,nz),'b',zeros(0,1),'lb',lb,'ub',ub);
tQ = tic;
%% 注意: Ruiz 前処理はここでは使わない. 単発コールドのベンチでは反復数を
%% 2.3倍削減 (3925->1725, omega=1e2とセット) したが, 閉ループでは Ruiz の
%% スケールが周期ごとに変わりウォームスタートが壊れ, 収束率 79%->29% に
%% 悪化して墜落した (実測). 許容誤差スケーリング (Dx/Du) のみとする.
qpo = topt.qp;
if isfield(topt,'fastQP') && topt.fastQP
    qpo.fixedIter = true;  qpo.maxIter = 300;       %% 固定反復 (決定的, ~9ms)
end
if isfield(topt,'useCpp') && topt.useCpp && exist('pipg_mex','file') == 3
    [z,qi] = scpk.solveQPC(prob, qpo, z0);          %% 手書きC++ (等価性検証済み)
else
    [z,qi] = scpk.solveQP(prob, qpo, z0);           %% MATLAB版フォールバック
end
dbg.qpTime = toc(tQ);  dbg.status = qi.status;  dbg.iters = qi.iters;
z0 = z;

du0 = z(iu(:,1)).*Du;
u0 = ur(:,1) + du0;
%% 基数0 (空力降下) では推力ゼロを厳守
if engk(1) == 0, u0(1:3) = 0; end
dbg.dxNorm = norm(dxc.*Dx.*sx(1:14)./sx(1:14));
%% 方式2 (姿勢内ループ) 用: MPC が予測する次節点の姿勢 = 姿勢コマンド
dx1 = z(ix(:,1)).*Dx;
q1 = xr(7:10,2) + dx1(7:10);
nq1 = norm(q1);  if nq1 > eps, q1 = q1/nq1; end
dbg.qCmd = q1;
end
