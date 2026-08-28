function [u0,zOut,qCmd,st,iters] = trackStepEmb(xcPhys, xr, ur, engk, cfg, tp, zWarm) %#codegen
%TRACKSTEPEMB  追従MPC 1周期 (組み込み向け: 生成コード可能な単一関数).
%
%   [U0,Z,QCMD,ST,ITERS] = TRACKSTEPEMB(XCPHYS, XR, UR, ENGK, CFG, TP, ZWARM)
%
%   TRACK6STEP と同一の数学 (LTV追従QP + PIPG) を, MATLAB Coder で純Cに落とせる
%   形 (スパース行列なし・トリプレット->CSC・明示ループ) で実装したもの.
%   参照のサンプリング (時刻/高度ディスパッチ) は呼び出し側で行う.
%
%   入力:
%     XCPHYS 現在状態 (物理単位 14: [r_I(3); v_B(3); q(4); w_B(3); m(kg)])
%     XR     参照状態 (無次元, 14 x H+1. 四元数は正規化済みであること)
%     UR     参照制御 (無次元, 7 x H)
%     ENGK   点火基数 (1 x H)
%     CFG    機体定数 (scpk.model6 / modelFalcon9)
%     TP     追従パラメータ (scpk.trackParams)
%     ZWARM  前周期の解 (21*H x 1. 初回は zeros(21*H,1))
%
%   出力:
%     U0     適用する制御 (無次元 [T_B(3); flap(4)])
%     ZOUT   今回の解 (次周期のウォームスタート)
%     QCMD   姿勢コマンド (方式2の内ループ用: MPC予測の次節点姿勢, 正規化済み)
%     ST     QP状態 (1=converged, 0=maxIter, 4=numerical)
%     ITERS  QP反復数
%
%   See also SCPK.TRACK6STEP, SCPK.TRACKPARAMS, SCPK.PLANITEREMB
nx = 14;  nu = 7;
H = size(ur, 2);
sc = cfg.sc;
sx = [sc.L; sc.L; sc.L; sc.V; sc.V; sc.V; 1; 1; 1; 1; ...
      1/sc.T; 1/sc.T; 1/sc.T; cfg.m0];
xc = zeros(nx,1);
for i = 1:nx, xc(i) = xcPhys(i)/sx(i); end

Dx = tp.Dx;  Du = tp.Du;
nz = nx*H + nu*H;
ox = 0;  ou = nx*H;                       %% 変数: [zx_1..zx_H ; zu_0..zu_{H-1}]

%% ---- コスト (対角) ----
Pd = zeros(nz,1);  q = zeros(nz,1);
for k = 1:H
    for i = 1:nx, Pd(ox+nx*(k-1)+i) = tp.wx(i); end
    for i = 1:nu, Pd(ou+nu*(k-1)+i) = tp.rCtrl; end
end
for i = 1:nx
    Pd(ox+nx*(H-1)+i) = Pd(ox+nx*(H-1)+i)*tp.wTerm;   %% 終端重み
end
for j = 1:nz, Pd(j) = Pd(j) + tp.reg; end

%% ---- LTV離散化 (計画と同じ linDisc6All を sigma=1 で流用) ----
sig1 = ones(1,H);  ph1 = ones(1,H);  dtv = zeros(1,H);
for k = 1:H, dtv(k) = tp.dtau; end
[AdA,BdA,SdA,cdA] = scpk.linDisc6All(xr, ur, 1, ph1, dtv, cfg);

%% ---- 等式制約 G z = d (トリプレット組み立て) ----
m = nx*H;
ntMax = H*(nx + nx*nx + nx*nu);
ti = zeros(ntMax,1);  tj = zeros(ntMax,1);  tv = zeros(ntMax,1);
d = zeros(m,1);
dxc = zeros(nx,1);
for i = 1:nx, dxc(i) = (xc(i) - xr(i,1))/Dx(i); end
nt = 0;
for k = 1:H
    r0 = nx*(k-1);
    Ad = AdA(:,:,k);  Bd = BdA(:,:,k);
    %% 参照の離散化残差 dk = (Ad xr_k + Bd ur_k + cd - xr_{k+1})./Dx
    for i = 1:nx
        s = SdA(i,k) + cdA(i,k) - xr(i,k+1);
        for j = 1:nx, s = s + Ad(i,j)*xr(j,k); end
        for j = 1:nu, s = s + Bd(i,j)*ur(j,k); end
        d(r0+i) = s/Dx(i);
    end
    %% I on zx_k
    for i = 1:nx
        nt = nt + 1;  ti(nt) = r0+i;  tj(nt) = ox+nx*(k-1)+i;  tv(nt) = 1;
    end
    if k == 1
        %% 初期偏差は右辺へ: d += Ãd*dxc
        for i = 1:nx
            s = 0;
            for j = 1:nx, s = s + Ad(i,j)*Dx(j)*dxc(j); end
            d(r0+i) = d(r0+i) + s/Dx(i);
        end
    else
        %% -Ãd on zx_{k-1}
        for i = 1:nx
            for j = 1:nx
                v = -Ad(i,j)*Dx(j)/Dx(i);
                if v ~= 0
                    nt = nt + 1;  ti(nt) = r0+i;  tj(nt) = ox+nx*(k-2)+j;  tv(nt) = v;
                end
            end
        end
    end
    %% -B̃d on zu_k
    for i = 1:nx
        for j = 1:nu
            v = -Bd(i,j)*Du(j)/Dx(i);
            if v ~= 0
                nt = nt + 1;  ti(nt) = r0+i;  tj(nt) = ou+nu*(k-1)+j;  tv(nt) = v;
            end
        end
    end
end

%% ---- 箱制約 (物理制約 - 参照) ----
lb = -1e20*ones(nz,1);  ub = 1e20*ones(nz,1);
sinG = sin(cfg.veh.tvcMax);
for k = 1:H
    o1 = ou + nu*(k-1);
    Tmax = engk(k)*cfg.Tmax1;
    Tmin = engk(k)*cfg.Tmin1;
    lb(o1+1) = (Tmin - ur(1,k))/Du(1);   ub(o1+1) = (Tmax - ur(1,k))/Du(1);
    Tlat = Tmax*sinG;
    lb(o1+2) = (-Tlat - ur(2,k))/Du(2);  ub(o1+2) = (Tlat - ur(2,k))/Du(2);
    lb(o1+3) = (-Tlat - ur(3,k))/Du(3);  ub(o1+3) = (Tlat - ur(3,k))/Du(3);
    for i = 4:7
        lb(o1+i) = (-cfg.veh.flapTrim - ur(i,k))/Du(i);
        ub(o1+i) = ((cfg.veh.flapMax - cfg.veh.flapTrim) - ur(i,k))/Du(i);
    end
    if engk(k) == 0
        for i = 1:3
            lb(o1+i) = (0 - ur(i,k))/Du(i);  ub(o1+i) = lb(o1+i);
        end
    end
end

%% ---- CSC化 -> PIPG (Ruizなし: ウォームスタート保護のため許容誤差スケールのみ) ----
[jc,ir,vv] = tri2csc(ti,tj,tv,nt,nz);
z0 = zeros(nz,1);
if numel(zWarm) == nz
    for j = 1:nz, z0(j) = zWarm(j); end
end
[z,st,iters] = pipgCsc(Pd,q,jc,ir,vv,d,m,m,nz,lb,ub,tp,z0);
zOut = z;

%% ---- 復元 ----
u0 = zeros(nu,1);
for i = 1:nu, u0(i) = ur(i,1) + z(ou+i)*Du(i); end
if engk(1) == 0
    u0(1) = 0;  u0(2) = 0;  u0(3) = 0;    %% 基数0 (空力降下) は推力ゼロ厳守
end
qCmd = zeros(4,1);
for i = 1:4, qCmd(i) = xr(6+i,2) + z(ox+6+i)*Dx(6+i); end
nq = sqrt(qCmd(1)^2+qCmd(2)^2+qCmd(3)^2+qCmd(4)^2);
if nq > 1e-12, qCmd = qCmd/nq; end
end


function [jc,ir,vv] = tri2csc(ti,tj,tv,nt,n) %#codegen
%TRI2CSC  トリプレット -> CSC (planIterEmb と同一).
cnt = zeros(n,1);
for k = 1:nt, cnt(tj(k)) = cnt(tj(k)) + 1; end
jc = zeros(n+1,1);  jc(1) = 1;
for j = 1:n, jc(j+1) = jc(j) + cnt(j); end
fill = zeros(n,1);
ir = zeros(nt,1);  vv = zeros(nt,1);
for k = 1:nt
    j = tj(k);  p = jc(j) + fill(j);
    ir(p) = ti(k);  vv(p) = tv(k);  fill(j) = fill(j) + 1;
end
end


function [z,st,iters] = pipgCsc(Pd,q,jc,ir,vv,d,neq,m,n,lb,ub,o,z0) %#codegen
%PIPGCSC  PIPG (pipg_mex.cpp / planIterEmb と同一アルゴリズム, CSC明示ループ).
z = z0;  w = zeros(m,1);
st = int32(0);  iters = int32(o.maxIter);
lam = 0;  for j = 1:n, if abs(Pd(j)) > lam, lam = abs(Pd(j)); end, end
x = ones(n,1)/sqrt(n);  sig = 0;
tmpm = zeros(m,1);  tmpn = zeros(n,1);
for it = 1:o.powerIter
    tmpm(:) = 0;
    for j = 1:n
        if x(j) ~= 0
            for k = jc(j):jc(j+1)-1, tmpm(ir(k)) = tmpm(ir(k)) + vv(k)*x(j); end
        end
    end
    for j = 1:n
        s = 0;
        for k = jc(j):jc(j+1)-1, s = s + vv(k)*tmpm(ir(k)); end
        tmpn(j) = s;
    end
    sig = 0;  for j = 1:n, sig = sig + tmpn(j)^2; end
    sig = sqrt(sig);
    if sig < eps, sig = 0; break; end
    for j = 1:n, x(j) = tmpn(j)/sig; end
end
al = 2/(lam + sqrt(lam^2 + 4*o.omega*sig));
be = o.omega*al;
if ~isfinite(al) || al <= 0, st = int32(4); return; end
zb = z;  wb = w;  zPrev = z;
fixed = o.fixedIter > 0;
for k2 = 1:o.maxIter
    for j = 1:n
        s = 0;
        for k = jc(j):jc(j+1)-1, s = s + vv(k)*wb(ir(k)); end
        zv = zb(j) - al*(Pd(j)*zb(j) + q(j) + s);
        if zv < lb(j), zv = lb(j); elseif zv > ub(j), zv = ub(j); end
        tmpn(j) = zv;
    end
    tmpm(:) = 0;
    for j = 1:n
        xj = 2*tmpn(j) - zb(j);
        if xj ~= 0
            for k = jc(j):jc(j+1)-1, tmpm(ir(k)) = tmpm(ir(k)) + vv(k)*xj; end
        end
    end
    for i = 1:m
        wv = wb(i) + be*(tmpm(i) - d(i));
        if i > neq && wv < 0, wv = 0; end
        tmpm(i) = wv;
    end
    for j = 1:n, zb(j) = (1-o.rho)*zb(j) + o.rho*tmpn(j); end
    for i = 1:m, wb(i) = (1-o.rho)*wb(i) + o.rho*tmpm(i); end
    if mod(k2, o.checkEvery) == 0
        bad = false;
        for j = 1:n, if ~isfinite(tmpn(j)), bad = true; break; end, end
        if ~bad, for i = 1:m, if ~isfinite(tmpm(i)), bad = true; break; end, end, end
        if bad, st = int32(4); iters = int32(k2); z = zPrev; return; end
        zPrev = tmpn;
        [rp,rd] = residCsc(Pd,q,jc,ir,vv,d,neq,m,n,lb,ub,zb,wb);
        if rp < o.tolPri && rd < o.tolDua && ~fixed
            st = int32(1);  iters = int32(k2);
            for j = 1:n
                zv = zb(j);
                if zv < lb(j), zv = lb(j); elseif zv > ub(j), zv = ub(j); end
                z(j) = zv;
            end
            return
        end
    end
end
for j = 1:n
    zv = zb(j);
    if zv < lb(j), zv = lb(j); elseif zv > ub(j), zv = ub(j); end
    z(j) = zv;
end
[rp,rd] = residCsc(Pd,q,jc,ir,vv,d,neq,m,n,lb,ub,z,wb);
if rp < o.tolPri && rd < o.tolDua, st = int32(1); end
end


function [rp,rd] = residCsc(Pd,q,jc,ir,vv,d,neq,m,n,lb,ub,z,w) %#codegen
Cz = zeros(m,1);
for j = 1:n
    if z(j) ~= 0
        for k = jc(j):jc(j+1)-1, Cz(ir(k)) = Cz(ir(k)) + vv(k)*z(j); end
    end
end
rpa = 0;
for i = 1:neq, a = abs(Cz(i)-d(i)); if a > rpa, rpa = a; end, end
for i = neq+1:m, a = Cz(i)-d(i); if a > rpa, rpa = a; end, end
sPri = 1;
for i = 1:m
    if abs(Cz(i)) > sPri, sPri = abs(Cz(i)); end
    if abs(d(i)) > sPri, sPri = abs(d(i)); end
end
rp = rpa/sPri;
rda = 0;  sDua = 1;
Ctw = zeros(n,1);
for j = 1:n
    s = 0;
    for k = jc(j):jc(j+1)-1, s = s + vv(k)*w(ir(k)); end
    Ctw(j) = s;
end
for j = 1:n
    g = Pd(j)*z(j) + q(j) + Ctw(j);
    if z(j) <= lb(j) + 1e-12 && g > 0, g = 0; end
    if z(j) >= ub(j) - 1e-12 && g < 0, g = 0; end
    a = abs(g);  if a > rda, rda = a; end
    if abs(Pd(j)*z(j)) > sDua, sDua = abs(Pd(j)*z(j)); end
    if abs(q(j)) > sDua, sDua = abs(q(j)); end
    if abs(Ctw(j)) > sDua, sDua = abs(Ctw(j)); end
end
rd = rda/sDua;
end
