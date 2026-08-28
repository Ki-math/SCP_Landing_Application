function [prob,ix,D] = buildTrack(x0,xr,ur,gr,eng,dt,cfg,opt,xl,ul,gl)
%BUILDTRACK  追従MPC の凸QPを許容誤差スケール座標で組む.
%
%   [PROB,IX,D] = BUILDTRACK(...) は SOLVEQP が解ける形の PROB と,
%   決定変数の索引 IX, スケール係数 D を返す.
%
%   決定変数 (すべて許容誤差で無次元化済み)
%     z = [x_0..x_N ; u_0..u_{N-1} ; gam_0..gam_{N-1} ; nu+ ; nu-]
%
%   単純な上下限 (推力範囲, フラップ振幅, スラック非負, 角速度/高度/質量) は
%   箱制約 lb/ub に入れる. 一般不等式に残すのは推力錐とジンバル錐だけ.
nx = 7; nu = 3; N = size(ur,2);
if nargin < 9  || isempty(xl), xl = xr; end
if nargin < 10 || isempty(ul), ul = ur; end
if nargin < 11 || isempty(gl), gl = gr; end

%% --- スケール係数 (モデル無次元 -> 許容誤差単位) ---
sc = cfg.sc;  t = opt.tol;
D.x = [t.pos/sc.L; t.pos/sc.L; t.vel/sc.V; t.vel/sc.V; ...
       deg2rad(t.ang); deg2rad(t.rate)*sc.T; t.mass/cfg.m0];
D.u = [t.thr/cfg.Fs; t.thr/cfg.Fs; t.flap];
D.g = t.thr/cfg.Fs;
Dx = D.x; Du = D.u; Dg = D.g;

ix.x  = reshape(1:nx*(N+1),nx,N+1);  n0 = nx*(N+1);
ix.u  = reshape(n0+(1:nu*N),nu,N);   n0 = n0 + nu*N;
ix.g  = n0 + (1:N);                  n0 = n0 + N;
ix.vp = reshape(n0+(1:3*N),3,N);     n0 = n0 + 3*N;
ix.vm = reshape(n0+(1:3*N),3,N);     n0 = n0 + 3*N;
nz = n0; ix.nz = nz; ix.N = N; ix.D = D;

%% --- 離散化 (線形化点まわり, expm 非依存) ---
Ad=zeros(nx,nx,N); Bd=zeros(nx,nu,N); Bg=zeros(nx,1,N); cd=zeros(nx,N);
Tmin=zeros(1,N); Tmax=zeros(1,N);
for k = 1:N
    ck = cfg;
    if eng(k) >= 3, ck.cB = cfg.cBunit/3; else, ck.cB = cfg.cBunit; end
    Tmin(k) = eng(k)*cfg.Tmin1;  Tmax(k) = eng(k)*cfg.Tmax1;
    [f,A,B,Bs] = scpk.dynamics(xl(:,k),ul(:,k),gl(k),ck);
    c = f - A*xl(:,k) - B*ul(:,k) - Bs*gl(k);
    [Ad(:,:,k),Bk,cd(:,k)] = scpk.discretize(A,[B Bs],c,dt);
    Bd(:,:,k) = Bk(:,1:nu);  Bg(:,:,k) = Bk(:,nu+1);
end

%% --- コスト: スケール座標での二乗和 ---
wx = [opt.w.pos; opt.w.pos; opt.w.vel; opt.w.vel; opt.w.ang; opt.w.rate; opt.w.mass];
%% 正則化は全変数に一様に入れる. ゼロ重みの変数 (質量) が平坦方向を作ると
%% 前処理の列スケーリングがそこを増幅し, かえって条件数が悪化する.
P = opt.reg*speye(nz);  q = zeros(nz,1);
for k = 1:N+1
    wk = wx * (1 + (opt.w.term-1)*(k==N+1));
    id = ix.x(:,k);
    P(id,id) = P(id,id) + 2*spdiags(wk,0,nx,nx);
    q(id)    = q(id) - 2*wk.*(xr(:,k)./Dx);
end
for k = 1:N
    id = ix.u(:,k);
    P(id,id) = P(id,id) + 2*opt.w.ctrl*speye(nu);
    q(id)    = q(id) - 2*opt.w.ctrl*(ur(:,k)./Du);
end
q(ix.vp(:)) = opt.lamVC;  q(ix.vm(:)) = opt.lamVC;

%% --- 等式: 初期条件 + 線形化動力学 (スケール座標) ---
E3 = zeros(nx,3); E3(3,1)=1; E3(4,2)=1; E3(6,3)=1;
iDx = 1./Dx;
neq = nx*(N+1);
G = spalloc(neq,nz,neq*(2*nx+nu+8));  g = zeros(neq,1);
G(1:nx, ix.x(:,1)) = speye(nx);  g(1:nx) = x0./Dx;
for k = 1:N
    r = nx*k + (1:nx);
    G(r, ix.x(:,k+1)) =  speye(nx);
    G(r, ix.x(:,k))   = -diag(iDx)*Ad(:,:,k)*diag(Dx);
    G(r, ix.u(:,k))   = -diag(iDx)*Bd(:,:,k)*diag(Du);
    G(r, ix.g(k))     = -diag(iDx)*Bg(:,:,k)*Dg;
    G(r, ix.vp(:,k))  = -diag(iDx)*E3;
    G(r, ix.vm(:,k))  =  diag(iDx)*E3;
    g(r) = cd(:,k)./Dx;
end

%% --- 一般不等式: 推力錐 + ジンバル錐 ---
ph = 2*pi*(0:opt.nCone-1).'/opt.nCone;  Dc = [cos(ph) sin(ph)];
nrow = N*(opt.nCone + 2);
A = spalloc(nrow,nz,nrow*4);  b = zeros(nrow,1);  rr = 0;
for k = 1:N
    A(rr+(1:opt.nCone), ix.u(1:2,k)) = Dc.*[Du(1) Du(2)];
    A(rr+(1:opt.nCone), ix.g(k))     = -opt.coneShrink*Dg;
    rr = rr + opt.nCone;
    A(rr+1, ix.u(2,k)) =  Du(2);  A(rr+1, ix.u(1,k)) = -cfg.tanGim*Du(1);
    A(rr+2, ix.u(2,k)) = -Du(2);  A(rr+2, ix.u(1,k)) = -cfg.tanGim*Du(1);
    rr = rr + 2;
end

%% --- 箱制約 ---
lb = -inf(nz,1);  ub = inf(nz,1);
%% 高度下限は現在高度と参照の下側にも余裕を持たせる. 終端付近で機体が
%% hmin を下回ると実行可能領域が空になり, 制約が破れる (実測で最大3.2).
hFloor = min([cfg.hmin, min(xr(1,:)), x0(1)]) - opt.hMargin/(cfg.sc.L);
lb(ix.x(1,:)) = hFloor/Dx(1);
lb(ix.x(6,:)) = -cfg.omMax/Dx(6);  ub(ix.x(6,:)) = cfg.omMax/Dx(6);
lb(ix.x(7,:)) = (cfg.veh.dryMass/cfg.m0)/Dx(7);
for k = 1:N
    lb(ix.g(k)) = Tmin(k)/Dg;  ub(ix.g(k)) = Tmax(k)/Dg;
    lb(ix.u(1,k)) = 0;
    lb(ix.u(3,k)) = -1/Du(3);  ub(ix.u(3,k)) = 1/Du(3);
end
lb(ix.vp(:)) = 0;  lb(ix.vm(:)) = 0;

prob = struct('P',P,'q',q,'G',G,'g',g,'A',A,'b',b,'lb',lb,'ub',ub);
end
