function [xs,us,gs,ss,st,iters,nu,step,zOut] = planIterEmb(x0nd,xT,xl,ul,gl,sigl,phase,eng,dtv,tiltN,cfg,pp,qp,zWarm) %#codegen
%PLANITEREMB  計画SCPの1反復を単一関数で実行 (組み込み/フルC生成用).
%
%   [XS,US,GS,SS,ST,ITERS,NU,STEP] = PLANITEREMB(...)
%
%   処理: 線形化+離散化 -> QP組立(トリプレット->CSC) -> Ruiz -> PIPG -> 復元.
%   buildPlan6 + precondition + solveQP と同一の数学 (等価性はテストで担保).
%   疎行列型を使わず全て明示ループ/配列で書く (生成Cが手書き同等の速度).
%
%   入力 (全て数値):
%     X0ND 14x1 初期状態(モデル無次元), XT 12x1 終端目標
%     XL 14x(N+1), UL 7xN, GL 1xN, SIGL 1xnPh  線形化点
%     PHASE 1xN, ENG 1xN, DTV 1xN, TILTN 1x(N+1) 傾斜上限[rad] (179deg=無効)
%     CFG   scpk.model6 の struct
%     PP    計画パラメータ (scpk.planParams で生成; 数値のみ)
%     QP    PIPG設定 (maxIter,fixedIter,tolPri,tolDua,omega,rho,checkEvery,
%             powerIter,certAfter,certTol,certEps)
%   出力: 更新された線形化点 XS/US/GS/SS, QPステータス ST (0-4), 反復数,
%         仮想制御和 NU, ステップ幅 STEP (許容誤差単位).
%
%   See also SCPK.PLANPARAMS, SCPK.PLAN6FT, SCPK.BUILDPLAN6
nx = 14;  nu7 = 7;  nvc = 10;
N = size(ul,2);  nPh = numel(sigl);
sc = cfg.sc;

%% ---- スケール ----
Dx = [ones(3,1)*pp.tolPos/sc.L; ones(3,1)*pp.tolVel/sc.V; ones(4,1)*pp.tolQuat; ...
      ones(3,1)*(pp.tolRate*pi/180)*sc.T; pp.tolMass/cfg.m0];
Du = [ones(3,1)*pp.tolThr/cfg.Fs; ones(4,1)*pp.tolFlap];
Dg = pp.tolThr/cfg.Fs;  Dsig = pp.tolSig/sc.T;

%% ---- 変数レイアウト ----
ox = 0;                       % x: 1..nx*(N+1)
ou = nx*(N+1);                % u
og = ou + nu7*N;              % g
ovp = og + N;  ovm = ovp + nvc*N;
osg0 = ovm + nvc*N;           % sigma
oep = osg0 + nPh;  oem = oep + 12;
% softGlide スラック
idxT = 0;  for k = 1:N, if phase(k) >= pp.phaseTight, idxT = idxT + 1; end, end
nP2 = 8;  nGT = 0;
if pp.softGlide > 0, nGT = (idxT+1)*2*nP2; end
osg = oem + 12;
nz = osg + nGT;

%% ---- 線形化+離散化 ----
[Ad,Bd,Sd,cd] = scpk.linDisc6All(xl,ul,sigl,phase,dtv,cfg);

%% ---- コスト (P対角, q) ----
Pd = ones(nz,1)*pp.reg;
if pp.wTilt > 0                     % 傾斜正則化: 直立想定ノードの q3,q4 (buildPlan6 と同一)
    for k = 1:N+1
        if tiltN(k) <= deg2rad(20)
            Pd(ox+(k-1)*nx+9)  = Pd(ox+(k-1)*nx+9)  + pp.wTilt;
            Pd(ox+(k-1)*nx+10) = Pd(ox+(k-1)*nx+10) + pp.wTilt;
        end
    end
end
q = zeros(nz,1);
q(ox+nx*N+14) = q(ox+nx*N+14) - pp.wFuel;         % 終端質量 (x(:,N+1) の14成分目)
for i = 1:nvc*N, q(ovp+i) = pp.lamVC;  q(ovm+i) = pp.lamVC; end
for i = 1:12,    q(oep+i) = pp.lamTerm; q(oem+i) = pp.lamTerm; end
for i = 1:nGT,   q(osg+i) = pp.lamGlide; end

%% ---- 等式 (トリプレット) ----
CAP = 90000;
ti = zeros(CAP,1);  tj = zeros(CAP,1);  tv = zeros(CAP,1);  nt = 0;
neq = nx*(N+1) + 12;
d = zeros(neq + 40*N + (idxT+1)*2*nP2 + N + (N+1)*nP2 + 12*N, 1);  % [g; b] (上限確保)
% x0
for i = 1:nx
    nt=nt+1; ti(nt)=i; tj(nt)=ox+i; tv(nt)=1;
    d(i) = x0nd(i)/Dx(i);
end
% 動力学
for k = 1:N
    r0 = nx*k;
    for i = 1:nx
        nt=nt+1; ti(nt)=r0+i; tj(nt)=ox+nx*k+i; tv(nt)=1;    % x_{k+1}
    end
    for i = 1:nx
        for j = 1:nx
            v = -Ad(i,j,k)*Dx(j)/Dx(i);
            if v ~= 0, nt=nt+1; ti(nt)=r0+i; tj(nt)=ox+nx*(k-1)+j; tv(nt)=v; end
        end
        for j = 1:nu7
            v = -Bd(i,j,k)*Du(j)/Dx(i);
            if v ~= 0, nt=nt+1; ti(nt)=r0+i; tj(nt)=ou+nu7*(k-1)+j; tv(nt)=v; end
        end
        v = -Sd(i,k)*Dsig/Dx(i);
        if v ~= 0, nt=nt+1; ti(nt)=r0+i; tj(nt)=osg0+phase(k); tv(nt)=v; end
        d(r0+i) = cd(i,k)/Dx(i);
    end
    for j = 1:nvc                                             % 仮想制御 (行4..13)
        nt=nt+1; ti(nt)=r0+3+j; tj(nt)=ovp+nvc*(k-1)+j; tv(nt)=-1/Dx(3+j);
        nt=nt+1; ti(nt)=r0+3+j; tj(nt)=ovm+nvc*(k-1)+j; tv(nt)= 1/Dx(3+j);
    end
end
% 終端 (12成分)
iT = [1 2 3 4 5 6 8 9 10 11 12 13];
for i = 1:12
    r = nx*(N+1) + i;
    nt=nt+1; ti(nt)=r; tj(nt)=ox+nx*N+iT(i); tv(nt)=Dx(iT(i));
    nt=nt+1; ti(nt)=r; tj(nt)=oep+i; tv(nt)=-1;
    nt=nt+1; ti(nt)=r; tj(nt)=oem+i; tv(nt)= 1;
    d(r) = xT(i);
end

%% ---- 不等式 (行番号は neq からの続き) ----
rI = neq;
% 推力錐の方向 (coneDirs と同一の生成則)
nRing = max(1, round(sqrt(pp.nCone/3)));
perRing = max(3, floor((pp.nCone-1)/nRing));
ncone = 1 + nRing*perRing;
Dc = zeros(ncone,3);  Dc(1,:) = [1 0 0];  ic = 1;
for i = 1:nRing
    a = pp.coneHalf*i/nRing;
    for j = 0:perRing-1
        b = 2*pi*j/perRing + pi*i/nRing;
        ic = ic+1;  Dc(ic,:) = [cos(a), sin(a)*cos(b), sin(a)*sin(b)];
    end
end
cg = cos(cfg.veh.tvcMax);
for k = 1:N
    for c = 1:ncone                                           % 錐
        rI = rI+1;
        for j = 1:3
            v = Dc(c,j)*Du(j);
            if v ~= 0, nt=nt+1; ti(nt)=rI; tj(nt)=ou+nu7*(k-1)+j; tv(nt)=v; end
        end
        nt=nt+1; ti(nt)=rI; tj(nt)=og+k; tv(nt)=-pp.coneShrink*Dg;
        d(rI) = 0;
    end
    rI = rI+1;                                                % ジンバル
    nt=nt+1; ti(nt)=rI; tj(nt)=ou+nu7*(k-1)+1; tv(nt)=-Du(1);
    nt=nt+1; ti(nt)=rI; tj(nt)=og+k; tv(nt)=cg*Dg;
    d(rI) = 0;
    nb = sqrt(ul(1,k)^2+ul(2,k)^2+ul(3,k)^2);                 % ロスレス線形化
    if nb < 1e-9, nb = 1e-9; end
    for s2 = [1 -1]
        rI = rI+1;
        for j = 1:3
            v = s2*(ul(j,k)/nb)*Du(j);
            if v ~= 0, nt=nt+1; ti(nt)=rI; tj(nt)=ou+nu7*(k-1)+j; tv(nt)=v; end
        end
        nt=nt+1; ti(nt)=rI; tj(nt)=og+k; tv(nt)=-s2*Dg;
        d(rI) = pp.lcTol;
    end
end
% 傾斜角/グライドスロープ (phaseTight ノード + 終端)
rTilt0 = sqrt((1-cos(pp.tiltMax))/2);
tg = tan(pp.glideSlope);
sgc = 0;
for kk = 1:N+1
    on = false;
    if kk <= N, on = phase(kk) >= pp.phaseTight; else, on = idxT > 0; end
    if ~on, continue; end
    for c = 1:nP2                                             % 傾斜
        ang = 2*pi*(c-1)/nP2;
        rI = rI+1;  sgc = sgc+1;
        nt=nt+1; ti(nt)=rI; tj(nt)=ox+nx*(kk-1)+9;  tv(nt)=cos(ang)*Dx(9);
        nt=nt+1; ti(nt)=rI; tj(nt)=ox+nx*(kk-1)+10; tv(nt)=sin(ang)*Dx(10);
        d(rI) = rTilt0;
    end
    for c = 1:nP2                                             % グライド (softならスラック)
        ang = 2*pi*(c-1)/nP2;
        rI = rI+1;  sgc = sgc+1;
        nt=nt+1; ti(nt)=rI; tj(nt)=ox+nx*(kk-1)+2; tv(nt)=tg*cos(ang)*Dx(2);
        nt=nt+1; ti(nt)=rI; tj(nt)=ox+nx*(kk-1)+3; tv(nt)=tg*sin(ang)*Dx(3);
        nt=nt+1; ti(nt)=rI; tj(nt)=ox+nx*(kk-1)+1; tv(nt)=-Dx(1);
        if pp.softGlide > 0
            nt=nt+1; ti(nt)=rI; tj(nt)=osg+sgc; tv(nt)=-1;
        end
        d(rI) = 0;
    end
end
% 高度の単調降下
if pp.monoDescent > 0
    for k = 1:N
        rI = rI+1;
        nt=nt+1; ti(nt)=rI; tj(nt)=ox+nx*k+1;     tv(nt)= Dx(1);
        nt=nt+1; ti(nt)=rI; tj(nt)=ox+nx*(k-1)+1; tv(nt)=-Dx(1);
        d(rI) = 0;
    end
end
% アクチュエータレート制約 (buildPlan6 と同一: 舵面 flapRate, 推力方向 tvcRate小角近似)
if pp.rateLim > 0
    for k = 1:N-1
        j2 = phase(k);
        dtk = dtv(k)*sigl(j2);
        dFl = cfg.veh.flapRate*sc.T*dtk;
        for i = 4:7
            for s2 = [1 -1]
                rI = rI+1;
                nt=nt+1; ti(nt)=rI; tj(nt)=ou+nu7*k+i;     tv(nt)= s2*Du(i);
                nt=nt+1; ti(nt)=rI; tj(nt)=ou+nu7*(k-1)+i; tv(nt)=-s2*Du(i);
                d(rI) = dFl;
            end
        end
        if eng(k) > 0 && eng(k+1) == eng(k)
            dT = eng(k)*cfg.Tmax1*(cfg.veh.tvcRate*sc.T)*dtk;
            for i = 2:3
                for s2 = [1 -1]
                    rI = rI+1;
                    nt=nt+1; ti(nt)=rI; tj(nt)=ou+nu7*k+i;     tv(nt)= s2*Du(i);
                    nt=nt+1; ti(nt)=rI; tj(nt)=ou+nu7*(k-1)+i; tv(nt)=-s2*Du(i);
                    d(rI) = dT;
                end
            end
        end
    end
end
% ノード毎 傾斜スケジュール
for kk = 1:N+1
    if tiltN(kk) >= deg2rad(178), continue; end
    rT = sqrt((1-cos(tiltN(kk)))/2);
    for c = 1:nP2
        ang = 2*pi*(c-1)/nP2;
        rI = rI+1;
        nt=nt+1; ti(nt)=rI; tj(nt)=ox+nx*(kk-1)+9;  tv(nt)=cos(ang)*Dx(9);
        nt=nt+1; ti(nt)=rI; tj(nt)=ox+nx*(kk-1)+10; tv(nt)=sin(ang)*Dx(10);
        d(rI) = rT;
    end
end
m = rI;

%% ---- 箱制約 ----
lb = -inf(nz,1);  ub = inf(nz,1);
hFloor = (cfg.hmin - pp.hMargin/sc.L)/Dx(1);
for k = 1:N+1
    lb(ox+nx*(k-1)+1) = hFloor;
    kk = k;  if kk > N, kk = N; end
    if phase(kk) >= pp.phaseTight, wL = pp.wMaxTight; else, wL = pp.wMaxFlip; end
    for i = 11:13
        lb(ox+nx*(k-1)+i) = -wL*sc.T/Dx(i);  ub(ox+nx*(k-1)+i) = wL*sc.T/Dx(i);
    end
    lb(ox+nx*(k-1)+14) = (cfg.veh.dryMass/cfg.m0)/Dx(14);
    if pp.bellyHold > 0 && phase(kk) == 1
        for i = 7:10
            c0 = pp.qBelly(i-6)/Dx(i);
            lb(ox+nx*(k-1)+i) = max(lb(ox+nx*(k-1)+i), c0 - pp.bellyHold);
            ub(ox+nx*(k-1)+i) = min(ub(ox+nx*(k-1)+i), c0 + pp.bellyHold);
        end
    end
    if k >= 2
        if pp.useDrBox > 0
            lb(ox+nx*(k-1)+3) = max(lb(ox+nx*(k-1)+3), (pp.drBox(1)/sc.L)/Dx(3));
            ub(ox+nx*(k-1)+3) = min(ub(ox+nx*(k-1)+3), (pp.drBox(2)/sc.L)/Dx(3));
        end
        if pp.crMax > 0
            lb(ox+nx*(k-1)+2) = max(lb(ox+nx*(k-1)+2), (-pp.crMax/sc.L)/Dx(2));
            ub(ox+nx*(k-1)+2) = min(ub(ox+nx*(k-1)+2), ( pp.crMax/sc.L)/Dx(2));
        end
    end
end
for k = 1:N
    Tmn = eng(k)*cfg.Tmin1;  Tmx = eng(k)*cfg.Tmax1;
    if phase(k) >= pp.phaseTight && pp.thrMaxTight > 0
        Tmx = min(Tmx, eng(k)*cfg.Tmax1*pp.thrMaxTight);
    end
    lb(og+k) = Tmn/Dg;  ub(og+k) = Tmx/Dg;
    lb(ou+nu7*(k-1)+1) = 0;
    for i = 4:7
        lb(ou+nu7*(k-1)+i) = -cfg.veh.flapTrim/Du(i);
        ub(ou+nu7*(k-1)+i) = (cfg.veh.flapMax - cfg.veh.flapTrim)/Du(i);
    end
end
for j = 1:nPh
    lb(osg0+j) = (pp.sigMin(j)/sc.T)/Dsig;  ub(osg0+j) = (pp.sigMax(j)/sc.T)/Dsig;
end
for i = 1:nvc*N, lb(ovp+i) = 0;  lb(ovm+i) = 0; end
for i = 1:12,    lb(oep+i) = 0;  lb(oem+i) = 0; end
for i = 1:nGT,   lb(osg+i) = 0; end
% トラストリージョン (境界方式)
for k = 1:N+1
    for i = 1:nx
        c0 = xl(i,k)/Dx(i);
        lb(ox+nx*(k-1)+i) = max(lb(ox+nx*(k-1)+i), c0 - pp.trX);
        ub(ox+nx*(k-1)+i) = min(ub(ox+nx*(k-1)+i), c0 + pp.trX);
    end
end
for k = 1:N
    for i = 1:nu7
        c0 = ul(i,k)/Du(i);
        lb(ou+nu7*(k-1)+i) = max(lb(ou+nu7*(k-1)+i), c0 - pp.trU);
        ub(ou+nu7*(k-1)+i) = min(ub(ou+nu7*(k-1)+i), c0 + pp.trU);
    end
    lb(og+k) = max(lb(og+k), gl(k)/Dg - pp.trU);
    ub(og+k) = min(ub(og+k), gl(k)/Dg + pp.trU);
end
for j = 1:nPh
    c0 = sigl(j)/Dsig;
    lb(osg0+j) = max(lb(osg0+j), c0 - pp.trSig);
    ub(osg0+j) = min(ub(osg0+j), c0 + pp.trSig);
end

%% ---- トリプレット -> CSC ----
[jc,ir,vv] = tri2csc(ti,tj,tv,nt,m,nz);

%% ---- Ruiz スケーリング ----
[colS,rowS,cs] = ruizCsc(jc,ir,vv,m,nz,Pd,15);
for j = 1:nz
    for k2 = jc(j):jc(j+1)-1
        vv(k2) = vv(k2)/rowS(ir(k2))*colS(j);
    end
end
Pd2 = zeros(nz,1);  q2 = zeros(nz,1);  lb2 = zeros(nz,1);  ub2 = zeros(nz,1);
for j = 1:nz
    Pd2(j) = cs*Pd(j)*colS(j)^2;  q2(j) = cs*q(j)*colS(j);
    lb2(j) = lb(j)/colS(j);       ub2(j) = ub(j)/colS(j);
end
d2 = zeros(m,1);
for i = 1:m, d2(i) = d(i)/rowS(i); end

%% ---- PIPG (ウォームスタート: 前回の無スケール解 zWarm を今回のスケールへ) ----
zh0 = zeros(nz,1);
if numel(zWarm) == nz
    for j = 1:nz, zh0(j) = zWarm(j)/colS(j); end
end
[zh,st,iters] = pipgCsc(Pd2,q2,jc,ir,vv,d2,neq,m,nz,lb2,ub2,qp,zh0);

%% ---- 復元 ----
z = zeros(nz,1);
for j = 1:nz, z(j) = colS(j)*zh(j); end
zOut = z;                                   %% 次回サイクルのウォームスタート用
xs = zeros(nx,N+1);  us = zeros(nu7,N);  gs = zeros(1,N);  ss = zeros(1,nPh);
for k = 1:N+1
    for i = 1:nx, xs(i,k) = z(ox+nx*(k-1)+i)*Dx(i); end
    nq = sqrt(xs(7,k)^2+xs(8,k)^2+xs(9,k)^2+xs(10,k)^2);
    if nq > eps, xs(7:10,k) = xs(7:10,k)/nq; end
end
for k = 1:N
    for i = 1:nu7, us(i,k) = z(ou+nu7*(k-1)+i)*Du(i); end
    gs(k) = z(og+k)*Dg;
end
for j = 1:nPh, ss(j) = z(osg0+j)*Dsig; end
nu = 0;
for i = 1:nvc*N
    if z(ovp+i) > 0, nu = nu + z(ovp+i); end
    if z(ovm+i) > 0, nu = nu + z(ovm+i); end
end
step = 0;
for k = 1:N+1
    for i = 1:nx
        a = abs(xs(i,k)-xl(i,k))/Dx(i);  if a > step, step = a; end
    end
end
for j = 1:nPh
    a = abs(ss(j)-sigl(j))/Dsig;  if a > step, step = a; end
end
end


function [jc,ir,vv] = tri2csc(ti,tj,tv,nt,m,n) %#codegen
%TRI2CSC  トリプレット -> CSC (列カウント + 前置和 + scatter).
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
%#ok<*NASGU>
m = m;   % 行数は検査用 (未使用)
end


function [colS,rowS,cs] = ruizCsc(jc,ir,vv,m,n,Pd,nIter) %#codegen
%RUIZCSC  Ruiz 平衡化 (ruiz_mex.cpp と同一).
va = abs(vv);  pd = abs(Pd);
colS = ones(n,1);  rowS = ones(m,1);
rn = zeros(m,1);  cn = zeros(n,1);
for it = 1:nIter
    rn(:) = 0;
    for j = 1:n
        for k = jc(j):jc(j+1)-1
            if va(k) > rn(ir(k)), rn(ir(k)) = va(k); end
        end
    end
    for i = 1:m, rn(i) = sqrt(max(rn(i),1e-12)); end
    for j = 1:n
        s = pd(j);
        for k = jc(j):jc(j+1)-1
            if va(k) > s, s = va(k); end
        end
        cn(j) = sqrt(max(s,1e-12));
    end
    for j = 1:n
        for k = jc(j):jc(j+1)-1, va(k) = va(k)/(rn(ir(k))*cn(j)); end
        pd(j) = pd(j)/cn(j)^2;
        colS(j) = colS(j)/cn(j);
    end
    for i = 1:m, rowS(i) = rowS(i)*rn(i); end
end
pmax = 1e-12;
for j = 1:n, if pd(j) > pmax, pmax = pd(j); end, end
cs = 1/pmax;
end


function [z,st,iters] = pipgCsc(Pd,q,jc,ir,vv,d,neq,m,n,lb,ub,o,z0) %#codegen
%PIPGCSC  PIPG (pipg_mex.cpp / solveQPEmb と同一アルゴリズム, CSC明示ループ).
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
zb = z;  wb = w;  zPrev = z;  wPrev = w;
fixed = o.fixedIter > 0;
for k2 = 1:o.maxIter
    % zn = clip(zb - al*(P zb + q + C' wb))
    for j = 1:n
        s = 0;
        for k = jc(j):jc(j+1)-1, s = s + vv(k)*wb(ir(k)); end
        zv = zb(j) - al*(Pd(j)*zb(j) + q(j) + s);
        if zv < lb(j), zv = lb(j); elseif zv > ub(j), zv = ub(j); end
        tmpn(j) = zv;
    end
    % wn = wb + be*(C(2 zn - zb) - d)
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
        zPrev = tmpn;  wPrev = tmpm;
        % 残差
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
for j = 1:n
    s = 0;
    for k = jc(j):jc(j+1)-1, s = s + vv(k)*w(ir(k)); end
    Pz = Pd(j)*z(j);
    gr = Pz + q(j) + s;
    zc = z(j) - gr;
    if zc < lb(j), zc = lb(j); elseif zc > ub(j), zc = ub(j); end
    a = abs(z(j) - zc);  if a > rda, rda = a; end
    if abs(Pz) > sDua, sDua = abs(Pz); end
    if abs(q(j)) > sDua, sDua = abs(q(j)); end
    if abs(s) > sDua, sDua = abs(s); end
end
rd = rda/sDua;
end
