function [prob,ix,D] = buildPlan(x0,xT,xl,ul,gl,eng,dt,cfg,opt)
%BUILDPLAN  軌道計画SCP の部分問題を許容誤差スケール座標で組む.
%
%   [PROB,IX,D] = BUILDPLAN(X0,XT,XL,UL,GL,ENG,DT,CFG,OPT)
%
%   決定変数 (すべて許容誤差で無次元化済み)
%     z = [x_0..x_N ; u_0..u_{N-1} ; gam_0..gam_{N-1} ; nu+ ; nu- ; e+ ; e-]
%       nu : 仮想制御 (v,omega の3式). 部分問題を常に実行可能にする
%       e  : 終端条件のスラック
%
%   目的  燃料最小 (終端質量最大) + 厳密ペナルティ + トラストリージョン
%   箱制約に入れるもの: 推力範囲, フラップ振幅, スラック非負, 角速度/高度/質量
%   一般不等式に残すもの: 推力錐, ジンバル錐, 終端許容箱
nx = 7; nu = 3; N = size(ul,2);
sc = cfg.sc;  t = opt.tol;
D.x = [t.pos/sc.L; t.pos/sc.L; t.vel/sc.V; t.vel/sc.V; ...
       deg2rad(t.ang); deg2rad(t.rate)*sc.T; t.mass/cfg.m0];
D.u = [t.thr/cfg.Fs; t.thr/cfg.Fs; t.flap];
D.g = t.thr/cfg.Fs;
Dx = D.x; Du = D.u; Dg = D.g;  iDx = 1./Dx;

ix.x  = reshape(1:nx*(N+1),nx,N+1);  n0 = nx*(N+1);
ix.u  = reshape(n0+(1:nu*N),nu,N);   n0 = n0 + nu*N;
ix.g  = n0 + (1:N);                  n0 = n0 + N;
ix.vp = reshape(n0+(1:3*N),3,N);     n0 = n0 + 3*N;
ix.vm = reshape(n0+(1:3*N),3,N);     n0 = n0 + 3*N;
ix.ep = n0 + (1:6);                  n0 = n0 + 6;
ix.em = n0 + (1:6);                  n0 = n0 + 6;
ix.lc = n0 + (1:N);                  n0 = n0 + N;   % ||T||=Gam 線形化スラック
nz = n0; ix.nz = nz; ix.N = N; ix.D = D;

%% --- 離散化 (線形化点まわり) ---
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

%% --- コスト ---
P = opt.reg*speye(nz);  q = zeros(nz,1);
for k = 1:N+1                            %% 近接型トラストリージョン
    id = ix.x(:,k);
    P(id,id) = P(id,id) + 2*opt.wTR*speye(nx);
    q(id)    = q(id) - 2*opt.wTR*(xl(:,k)./Dx);
end
for k = 1:N
    id = ix.u(:,k);
    P(id,id) = P(id,id) + 2*opt.wCtrl*speye(nu);
    q(id)    = q(id) - 2*opt.wCtrl*(ul(:,k)./Du);
end
q(ix.x(7,N+1)) = q(ix.x(7,N+1)) - opt.wFuel;   %% 終端質量最大化
q(ix.vp(:)) = opt.lamVC;  q(ix.vm(:)) = opt.lamVC;
q(ix.ep)    = opt.lamTerm; q(ix.em)   = opt.lamTerm;
q(ix.lc)    = opt.lamLC;

%% --- 等式: 初期条件 + 線形化動力学 + 終端 (スラック付) ---
E3 = zeros(nx,3); E3(3,1)=1; E3(4,2)=1; E3(6,3)=1;
neq = nx*(N+1) + 6;
G = spalloc(neq,nz,neq*(2*nx+nu+10));  g = zeros(neq,1);
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
r = nx*(N+1) + (1:6);
G(r, ix.x(1:6,N+1)) =  speye(6);
G(r, ix.ep)         = -speye(6);
G(r, ix.em)         =  speye(6);
%% 終端目標をモデル無次元 -> スケール後座標へ. 物理単位のまま比較すると
%% 高度で 1000 倍, 速度で 100 倍ずれ, 到達不能な目標になる.
xTn = [xT(1:2)/sc.L; xT(3:4)/sc.V; xT(5); xT(6)*sc.T];
g(r) = xTn./Dx(1:6);

%% --- 一般不等式: 推力錐 + ジンバル錐 ---
ph = 2*pi*(0:opt.nCone-1).'/opt.nCone;  Dc = [cos(ph) sin(ph)];
nrow = N*(opt.nCone + 4);
A = spalloc(nrow,nz,nrow*4);  b = zeros(nrow,1);  rr = 0;
for k = 1:N
    A(rr+(1:opt.nCone), ix.u(1:2,k)) = Dc.*[Du(1) Du(2)];
    A(rr+(1:opt.nCone), ix.g(k))     = -opt.coneShrink*Dg;
    rr = rr + opt.nCone;
    A(rr+1, ix.u(2,k)) =  Du(2);  A(rr+1, ix.u(1,k)) = -cfg.tanGim*Du(1);
    A(rr+2, ix.u(2,k)) = -Du(2);  A(rr+2, ix.u(1,k)) = -cfg.tanGim*Du(1);
    rr = rr + 2;
    %% ロスレス凸化の等式 ||T|| = Gam を線形化点まわりで課す.
    %% これが無いと Gam を下限に張り付かせたまま ||T|| を小さくでき,
    %% 実質「推力ゼロで自由落下」する解が最適になる.
    Tb = ul(1:2,k); nb = max(norm(Tb),1e-6); eT = (Tb/nb).';
    A(rr+1, ix.u(1:2,k)) =  eT.*[Du(1) Du(2)];  A(rr+1, ix.g(k)) = -Dg;  A(rr+1, ix.lc(k)) = -1;
    A(rr+2, ix.u(1:2,k)) = -eT.*[Du(1) Du(2)];  A(rr+2, ix.g(k)) =  Dg;  A(rr+2, ix.lc(k)) = -1;
    rr = rr + 2;
end

%% --- 箱制約 ---
lb = -inf(nz,1);  ub = inf(nz,1);
hFloor = min([cfg.hmin, min(xl(1,:)), x0(1)]) - opt.hMargin/sc.L;
lb(ix.x(1,:)) = hFloor/Dx(1);
lb(ix.x(6,:)) = -cfg.omMax/Dx(6);  ub(ix.x(6,:)) = cfg.omMax/Dx(6);
lb(ix.x(7,:)) = (cfg.veh.dryMass/cfg.m0)/Dx(7);
for k = 1:N
    lb(ix.g(k)) = Tmin(k)/Dg;  ub(ix.g(k)) = Tmax(k)/Dg;
    lb(ix.u(1,k)) = 0;
    lb(ix.u(3,k)) = -1/Du(3);  ub(ix.u(3,k)) = 1/Du(3);
end
lb(ix.vp(:)) = 0;  lb(ix.vm(:)) = 0;  lb(ix.lc) = 0;
tb = opt.tolBox(:)./[sc.L;sc.L;sc.V;sc.V;1/deg2rad(1);sc.T/deg2rad(1)];
tb(5) = deg2rad(opt.tolBox(5));  tb(6) = deg2rad(opt.tolBox(6))*sc.T;
lb(ix.ep) = 0;  ub(ix.ep) = inf;
lb(ix.em) = 0;  ub(ix.em) = inf;

prob = struct('P',P,'q',q,'G',G,'g',g,'A',A,'b',b,'lb',lb,'ub',ub);
end


