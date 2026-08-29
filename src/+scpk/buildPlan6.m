function [prob,ix,D] = buildPlan6(x0,xT,xl,ul,gl,sigl,eng,dt,cfg,opt)
%BUILDPLAN6  6自由度 動力降下 SCP の部分問題を許容誤差スケール座標で組む.
%
%   [PROB,IX,D] = BUILDPLAN6(X0,XT,XL,UL,GL,ENG,DT,CFG,OPT)
%
%   自由終端時刻: 各フェーズの時間を膨張係数 sigma_j として最適化変数に含める.
%   正規化時刻 tau in [0,1] で x' = sigma_j * f(x,u) と書き, 線形化すると
%     x' = sigma_bar*A*x + sigma_bar*B*u + f*sigma_j + F
%   となり, f が sigma に対する感度になる. つまり sigma を「追加の制御入力,
%   B 列が f」として扱えば既存の離散化がそのまま使える.
%   参考: Lee, Jung & Lee, Int. J. Aeronaut. Space Sci. 26:1890 (2025), Eq.39-43
%
%   決定変数 (すべて許容誤差で無次元化済み)
%     z = [x_0..x_N ; u_0..u_{N-1} ; gam_0..gam_{N-1} ; nu+ ; nu- ; e+ ; e-]
%       nu : 仮想制御. 速度3, 四元数4, 角速度3 の 10 行のみに入れる.
%            位置微分と質量微分は線形化誤差が小さく, 全 14 行に入れると
%            変数が 4 割増えるだけで得がない.
%       e  : 終端条件のスラック (12 成分: 位置3, 速度3, 四元数3, 角速度3)
%
%   DT はスカラーまたは 1xN のベクトル. 降下フェーズ (80-125 s) と着陸フェーズ
%   (10 s) で時間スケールが 10 倍違うため, 区間ごとに刻みを変えられるようにする.
%
%   箱制約に入れるもの: 推力大きさ, フラップ舵角, スラック非負, 角速度, 高度, 質量
%   一般不等式に残すもの: 推力錐 (多面体近似), ジンバル錐, ||T||=Gam の線形化
nx = 14;  nu = 7;  nvc = 10;  N = size(ul,2);
sc = cfg.sc;  t = opt.tol;
%% 診断用フラグ (既定 false: 挙動不変). 制約ブロックを個別に無効化する.
dropLoss  = isfield(opt,'dropLossless') && opt.dropLossless;  % ロスレス凸化 ||T||=Gam
dropCone  = isfield(opt,'dropCone')     && opt.dropCone;      % 推力錐
dropGim   = isfield(opt,'dropGimbal')   && opt.dropGimbal;    % ジンバル錐
dropGlide = isfield(opt,'dropGlide')    && opt.dropGlide;     % グライドスロープ/傾斜角

%% --- スケール係数 (モデル無次元 -> 許容誤差単位) ---
D.x = [repmat(t.pos/sc.L,3,1); repmat(t.vel/sc.V,3,1); repmat(t.quat,4,1); ...
       repmat(deg2rad(t.rate)*sc.T,3,1); t.mass/cfg.m0];
D.u = [repmat(t.thr/cfg.Fs,3,1); repmat(t.flap,4,1)];
D.g = t.thr/cfg.Fs;
D.sig = t.sig/sc.T;   %% 時間膨張の許容 (無次元)
Dx = D.x;  Du = D.u;  Dg = D.g;  iDx = 1./Dx;

ix.x  = reshape(1:nx*(N+1),nx,N+1);   n0 = nx*(N+1);
ix.u  = reshape(n0+(1:nu*N),nu,N);    n0 = n0 + nu*N;
ix.g  = n0 + (1:N);                   n0 = n0 + N;
ix.vp = reshape(n0+(1:nvc*N),nvc,N);  n0 = n0 + nvc*N;
ix.vm = reshape(n0+(1:nvc*N),nvc,N);  n0 = n0 + nvc*N;
nPh = max(opt.phase);
ix.sig = n0 + (1:nPh);                n0 = n0 + nPh;   %% 時間膨張係数
ix.ep = n0 + (1:12);                  n0 = n0 + 12;
ix.em = n0 + (1:12);                  n0 = n0 + 12;
%% 仮想状態(論文 Eq.53-55)の実務版: 状態経路制約(グライド/傾斜)をソフト化する
%% ためのスラック. 制御制約はハードのまま. これで部分問題が構造的に実行可能.
softG = isfield(opt,'softGlide') && opt.softGlide;
nP2gt = 8;  nGT = 0;  ix.sg = [];
if softG
    nTight0 = sum(opt.phase >= opt.phaseTight);
    if nTight0 >= 1
        nGT = (nTight0 + 1)*2*nP2gt;      % (拘束節点+終端) x (傾斜 nP2 + グライド nP2)
        ix.sg = n0 + (1:nGT);  n0 = n0 + nGT;
    end
end
nz = n0;  ix.nz = nz;  ix.N = N;  ix.D = D;

%% --- 離散化 (線形化点まわり) ---
if isscalar(dt), dtv = dt*ones(1,N); else, dtv = dt(:).'; end
Tmin=zeros(1,N); Tmax=zeros(1,N);
for k = 1:N
    Tmin(k) = eng(k)*cfg.Tmin1;  Tmax(k) = eng(k)*cfg.Tmax1;
    %% 終盤フェーズは推力上限を絞る. 1基でも最大 1.80 g で重力を上回るため,
    %% 上限を開けたままだと降下しきる直前に浮き上がる (終端高度 225 m の実例).
    if isfield(opt,'thrMaxTight') && opt.phase(k) >= opt.phaseTight
        Tmax(k) = min(Tmax(k), eng(k)*cfg.Tmax1*opt.thrMaxTight);
    end
end
%% 線形化+離散化 (ホットループ). C生成版 linDisc6All_mex があれば自動使用.
if exist('linDisc6All_mex','file') == 3
    [Ad,Bd,Sd,cd] = linDisc6All_mex(xl, ul, sigl(:).', double(opt.phase(:).'), dtv, cfg);
else
    [Ad,Bd,Sd,cd] = scpk.linDisc6All(xl, ul, sigl(:).', double(opt.phase(:).'), dtv, cfg);
end

%% --- コスト ---
P = opt.reg*speye(nz);  q = zeros(nz,1);
%% 傾斜の微小正則化: コストが傾斜に無関心 (平坦な谷) だと SCP が不必要に
%% 傾いた局所解に落ちる (鉛直降下できる場面でも±10m徘徊+12deg傾斜を実測).
%% 直立想定ノード (tiltN<=20deg) の四元数傾斜成分 q3,q4 を弱く罰して
%% 「必要なときだけ傾く」解を既定に. divert では lamTerm が勝つので阻害しない.
if isfield(opt,'wTilt') && ~isempty(opt.wTilt) && opt.wTilt > 0 ...
        && isfield(opt,'tiltMaxNode') && ~isempty(opt.tiltMaxNode)
    kUp = find(opt.tiltMaxNode(:).' <= deg2rad(20));
    if ~isempty(kUp)
        iq = [ix.x(9,kUp) ix.x(10,kUp)];
        P = P + sparse(iq, iq, opt.wTilt, nz, nz);
    end
end
%% 舵面使用の正則化: コストが舵面に無関心だと最適化はレート制限いっぱいの
%% バンバン動作で舵面を振り回し, 姿勢が5-15deg振動する不自然な計画になる
%% (グリッドフィン機で実測). 弱い2次ペナルティで滑らかな舵面計画を既定にする.
if isfield(opt,'wFlap') && ~isempty(opt.wFlap) && opt.wFlap > 0
    ifp = reshape(ix.u(4:7,1:N), 1, []);
    P = P + sparse(ifp, ifp, opt.wFlap, nz, nz);
end
%% トラストリージョンは境界で課す (ペナルティにしない). ペナルティだと線形化が
%% 悪い場面で解が遠くへ飛び, rho が負になって棄却の連鎖に陥る. 境界なら
%% 「どれだけ動いてよいか」が陽に決まり構造的に防げる. 箱制約なので PIPG では
%% 追加コストもゼロ.
q(ix.x(14,N+1)) = q(ix.x(14,N+1)) - opt.wFuel;  %% 終端質量最大化
q(ix.vp(:)) = opt.lamVC;   q(ix.vm(:)) = opt.lamVC;
q(ix.ep)    = opt.lamTerm; q(ix.em)    = opt.lamTerm;
if softG && nGT > 0
    if isfield(opt,'lamGlide'), lamG = opt.lamGlide; else, lamG = opt.lamTerm; end
    q(ix.sg) = lamG;                 % グライド/傾斜の違反ペナルティ (L1)
end

%% --- 等式: 初期条件 + 線形化動力学 + 終端 ---
E = zeros(nx,nvc);  E(4:13,:) = eye(nvc);       %% 仮想制御は速度/四元数/角速度へ
neq = nx*(N+1) + 12;
G = spalloc(neq,nz,neq*(2*nx+nu+14));  g = zeros(neq,1);
G(1:nx, ix.x(:,1)) = speye(nx);  g(1:nx) = x0./Dx;
for k = 1:N
    r = nx*k + (1:nx);
    G(r, ix.x(:,k+1)) =  speye(nx);
    G(r, ix.x(:,k))   = -diag(iDx)*Ad(:,:,k)*diag(Dx);
    G(r, ix.u(:,k))   = -diag(iDx)*Bd(:,:,k)*diag(Du);
    G(r, ix.sig(opt.phase(k))) = -diag(iDx)*Sd(:,k)*D.sig;
    G(r, ix.vp(:,k))  = -diag(iDx)*E;
    G(r, ix.vm(:,k))  =  diag(iDx)*E;
    g(r) = cd(:,k)./Dx;
end
%% 終端: 位置3, 速度3, 四元数のベクトル部3, 角速度3
iT = [1 2 3, 4 5 6, 8 9 10, 11 12 13];
r = nx*(N+1) + (1:12);
G(r, ix.x(iT,N+1)) =  diag(Dx(iT));
G(r, ix.ep)        = -speye(12);
G(r, ix.em)        =  speye(12);
g(r) = xT(:);   % xT は既に 12 成分 (位置3, 速度3, 四元数ベクトル部3, 角速度3)

%% --- 一般不等式 ---
Dc = scpk.coneDirs(opt.nCone, opt.coneHalf);
nPer = size(Dc,1) + 3;                          %% 錐 + ジンバル + LC 2本
A2 = spalloc(N*nPer,nz,N*nPer*6);  b2 = zeros(N*nPer,1);  rr = 0;
cg = cos(cfg.veh.tvcMax);
for k = 1:N
    nc = size(Dc,1);
    if ~dropCone
        A2(rr+(1:nc), ix.u(1:3,k)) = Dc.*Du(1:3).';
        A2(rr+(1:nc), ix.g(k))     = -opt.coneShrink*Dg;
    end  %% drop時は零行 (0<=0) で無効化
    rr = rr + nc;
    %% ジンバル錐: T_x >= cos(dmax)*Gam
    if ~dropGim
        A2(rr+1, ix.u(1,k)) = -Du(1);  A2(rr+1, ix.g(k)) = cg*Dg;
    end
    rr = rr + 1;
    %% ||T|| = Gam を線形化 (ロスレス凸化が非タイトなため直接課す)
    if ~dropLoss
        Tb = ul(1:3,k);  nb = max(norm(Tb),1e-9);  eT = (Tb/nb).';
        A2(rr+1, ix.u(1:3,k)) =  eT.*Du(1:3).';  A2(rr+1, ix.g(k)) = -Dg;
        A2(rr+2, ix.u(1:3,k)) = -eT.*Du(1:3).';  A2(rr+2, ix.g(k)) =  Dg;
        b2(rr+1) = opt.lcTol;  b2(rr+2) = opt.lcTol;
    end
    rr = rr + 2;
end

%% --- アクチュエータレート制約 (ノード間の制御変化率) ---
%% 舵面: |Δδ| <= flapRate*dt. 推力方向: 小角近似 T2,T3 ≈ T1*ジンバル角 より
%% |ΔT_{2,3}| <= N_E*Tmax1*tvcRate*dt を課す (点火基数が変わる境界は除外:
%% 点火・カットオフの不連続はレート制約の対象外). dt はフェーズ時間の
%% 線形化点 sigl に基づく近似 (SCP反復で更新される).
useRL = ~isfield(opt,'rateLim') || opt.rateLim;    % 既定で有効
if useRL
    nRL = (N-1)*2*6;                               % (Δflap4 + ΔT2,ΔT3) x 上下 x (N-1)
    A4 = spalloc(nRL, nz, nRL*2);  b4 = zeros(nRL,1);  r4 = 0;
    for k = 1:N-1
        j = opt.phase(k);
        dtk = dtv(k)*sigl(min(j,numel(sigl)));     % ノード間隔 [無次元時間]
        dFl = cfg.veh.flapRate*sc.T*dtk;           % 舵面変化許容 [rad]
        for i = 4:7
            A4(r4+1, ix.u(i,k+1)) =  Du(i);  A4(r4+1, ix.u(i,k)) = -Du(i);  b4(r4+1) = dFl;
            A4(r4+2, ix.u(i,k+1)) = -Du(i);  A4(r4+2, ix.u(i,k)) =  Du(i);  b4(r4+2) = dFl;
            r4 = r4 + 2;
        end
        if eng(k) > 0 && eng(k+1) == eng(k)        % 同一点火状態のノード間のみ
            dT = eng(k)*cfg.Tmax1*(cfg.veh.tvcRate*sc.T)*dtk;   % [無次元推力]
            for i = 2:3
                A4(r4+1, ix.u(i,k+1)) =  Du(i);  A4(r4+1, ix.u(i,k)) = -Du(i);  b4(r4+1) = dT;
                A4(r4+2, ix.u(i,k+1)) = -Du(i);  A4(r4+2, ix.u(i,k)) =  Du(i);  b4(r4+2) = dT;
                r4 = r4 + 2;
            end
        else
            r4 = r4 + 4;                           % 零行 (0<=0) で無効化
        end
    end
    A2 = [A2; A4];  b2 = [b2; b4];
end

%% --- 箱制約 ---
lb = -inf(nz,1);  ub = inf(nz,1);
%% 高度下限は固定値にする. 線形化点 xl を参照すると, xl が負のとき下限も
%% 負に緩んで制約が無意味になる (実際に高度 -196 m を通る解が出た).
hFloor = cfg.hmin - opt.hMargin/sc.L;
lb(ix.x(1,:)) = hFloor/Dx(1);
%% 角速度制限はフェーズ依存. 転回フェーズに 10deg/s を課すと 90deg 回るのに
%% 9 秒かかり, その間ずっと推力が横を向いて水平速度が溜まる (実測で 450 m).
%% 論文も角速度制約は精密着陸フェーズのみ (Eq.25 の t in [t3,tf]).
for k = 1:N+1
    kk = min(k,N);
    if opt.phase(kk) >= opt.phaseTight
        wLim = opt.wMaxTight;      %% 終盤: 厳しく
    else
        wLim = opt.wMaxFlip;       %% 転回まで: 素早く回せるように緩める
    end
    for i = 11:13
        lb(ix.x(i,k)) = -wLim*cfg.sc.T/Dx(i);  ub(ix.x(i,k)) = wLim*cfg.sc.T/Dx(i);
    end
end
lb(ix.x(14,:)) = (cfg.veh.dryMass/cfg.m0)/Dx(14);
%% ダウンレンジ/クロスレンジの行き過ぎ防止 (ループ抑制). 初期ノードは初期条件が
%% 等式で固定されるので, 箱は2ノード目以降に課す.
if isfield(opt,'drBox') && ~isempty(opt.drBox)      % [min max] [m]
    for k = 2:N+1
        lb(ix.x(3,k)) = max(lb(ix.x(3,k)), (opt.drBox(1)/sc.L)/Dx(3));
        ub(ix.x(3,k)) = min(ub(ix.x(3,k)), (opt.drBox(2)/sc.L)/Dx(3));
    end
end
if isfield(opt,'crMax') && ~isempty(opt.crMax)      % |cross| <= crMax [m]
    for k = 2:N+1
        lb(ix.x(2,k)) = max(lb(ix.x(2,k)), (-opt.crMax/sc.L)/Dx(2));
        ub(ix.x(2,k)) = min(ub(ix.x(2,k)), ( opt.crMax/sc.L)/Dx(2));
    end
end
for k = 1:N
    lb(ix.g(k)) = Tmin(k)/Dg;  ub(ix.g(k)) = Tmax(k)/Dg;
    lb(ix.u(1,k)) = 0;
    for i = 4:7
        lb(ix.u(i,k)) = -cfg.veh.flapTrim/Du(i);
        ub(ix.u(i,k)) = (cfg.veh.flapMax-cfg.veh.flapTrim)/Du(i);
    end
end
%% sigma は無次元時間 (物理秒 / sc.T) なので箱も無次元に揃える.
%% 秒のまま課すと下限 0.5 が無次元 0.5 (=5秒) として効き, 全フェーズが
%% 5.00 s に張り付く.
%% sigma の箱はフェーズごとに与えられる (opt.sigMin/sigMax はスカラーでも可)
smn = opt.sigMin(:).'; smx = opt.sigMax(:).';
if isscalar(smn), smn = smn*ones(1,nPh); end
if isscalar(smx), smx = smx*ones(1,nPh); end
lb(ix.sig) = (smn/cfg.sc.T)/D.sig;  ub(ix.sig) = (smx/cfg.sc.T)/D.sig;
lb(ix.vp(:)) = 0;  lb(ix.vm(:)) = 0;
%% --- トラストリージョン (境界方式) ---
%% 各変数の前回値からの変化幅を許容誤差単位で制限する.
for k = 1:N+1
    c0 = xl(:,k)./Dx;
    lb(ix.x(:,k)) = max(lb(ix.x(:,k)), c0 - opt.trX);
    ub(ix.x(:,k)) = min(ub(ix.x(:,k)), c0 + opt.trX);
end
for k = 1:N
    c0 = ul(:,k)./Du;
    lb(ix.u(:,k)) = max(lb(ix.u(:,k)), c0 - opt.trU);
    ub(ix.u(:,k)) = min(ub(ix.u(:,k)), c0 + opt.trU);
    lb(ix.g(k)) = max(lb(ix.g(k)), gl(k)/Dg - opt.trU);
    ub(ix.g(k)) = min(ub(ix.g(k)), gl(k)/Dg + opt.trU);
end
for j = 1:nPh
    c0 = sigl(j)/D.sig;
    lb(ix.sig(j)) = max(lb(ix.sig(j)), c0 - opt.trSig);
    ub(ix.sig(j)) = min(ub(ix.sig(j)), c0 + opt.trSig);
end
lb(ix.ep) = 0;     lb(ix.em) = 0;
if softG && ~isempty(ix.sg), lb(ix.sg) = 0;  ub(ix.sg) = inf; end   % スラック非負
tb = opt.tolBox(:)./[repmat(sc.L,3,1); repmat(sc.V,3,1); ones(3,1); repmat(1/(deg2rad(1)*sc.T),3,1)];
tb(7:9) = opt.tolBox(7:9);
%% 終端スラックに上限を掛けない. 掛けると目標に届かないとき終端スラックが
%% 飽和し, 上限のない仮想制御 nu が代わりに誤差を吸収してしまう (nu が下がらない).
%% 論文の仮想状態方式も終端条件はペナルティで結ぶだけで上限を持たない.
ub(ix.ep) = inf;  ub(ix.em) = inf;

%% --- 終盤フェーズの追加制約 (論文 Eq.24, Eq.26) ---
%% 傾斜角: cos(eta_max) <= 1 - 2*(q2^2+q3^2)  <=>  ||[q2;q3]|| <= rTilt
%% グライドスロープ: tan(gamma)*||[ry;rz]|| <= rx
%% どちらも凸錐なので正多角形で近似する.
nTight = sum(opt.phase >= opt.phaseTight) + 1;
if nTight > 1 && ~dropGlide
    rTilt = sqrt((1-cos(opt.tiltMax))/2);
    nP2 = 8;  ang = 2*pi*(0:nP2-1).'/nP2;  Dp = [cos(ang) sin(ang)];
    tg  = tan(opt.glideSlope);
    idx = find(opt.phase >= opt.phaseTight);
    kk  = [idx, N+1];
    A3 = spalloc(numel(kk)*2*nP2, nz, numel(kk)*2*nP2*3);  b3 = zeros(numel(kk)*2*nP2,1);  r3 = 0;
    for ii = 1:numel(kk)
        k = kk(ii);
        %% 傾斜角: Dp * [q2;q3] <= rTilt
        A3(r3+(1:nP2), ix.x(9,k))  = Dp(:,1)*Dx(9);
        A3(r3+(1:nP2), ix.x(10,k)) = Dp(:,2)*Dx(10);
        b3(r3+(1:nP2)) = rTilt;
        r3 = r3 + nP2;
        %% グライドスロープ: tg * Dp*[ry;rz] - rx <= 0
        A3(r3+(1:nP2), ix.x(2,k)) = tg*Dp(:,1)*Dx(2);
        A3(r3+(1:nP2), ix.x(3,k)) = tg*Dp(:,2)*Dx(3);
        A3(r3+(1:nP2), ix.x(1,k)) = -Dx(1);
        r3 = r3 + nP2;
    end
    %% ソフト化はグライドスロープ(位置)行のみ. 傾斜角(姿勢)はハードのまま.
    %% 姿勢までソフトにするとタンブリング解 (傾き170deg・1回転) が通ってしまう.
    if softG && ~isempty(ix.sg)
        for ii = 1:numel(kk)
            base = (ii-1)*2*nP2;
            for rr3 = base+nP2+(1:nP2)   % 後半 nP2 行 = グライドスロープ
                A3(rr3, ix.sg(rr3)) = -1;
            end
        end
    end
    A2 = [A2; A3(1:r3,:)];  b2 = [b2; b3(1:r3)];
end

%% --- 高度の単調降下 (再上昇の禁止) ---
%% x1(k+1) <= x1(k). これが無いと転回後に浮き上がってループを描く解が出る.
if isfield(opt,'monoDescent') && opt.monoDescent
    A5 = spalloc(N, nz, 2*N);  b5 = zeros(N,1);
    for k = 1:N
        A5(k, ix.x(1,k+1)) =  Dx(1);
        A5(k, ix.x(1,k))   = -Dx(1);
    end
    A2 = [A2; A5];  b2 = [b2; b5];
end

%% --- 傾斜角スケジュール (全ノード, ハード) ---
%% 転回開始で ~90deg を許し, 垂直整列までに単調に絞る. これが無いと最適化は
%% 「回しすぎて戻す」タンブル解を選ぶ (実測: 傾き170deg, 角速度91deg/s).
%% ||[q2;q3]|| <= sqrt((1-cos(tiltMax_k))/2) は凸なので正多角形で課す.
if isfield(opt,'tiltMaxNode') && ~isempty(opt.tiltMaxNode)
    nP4 = 8;  ang4 = 2*pi*(0:nP4-1).'/nP4;  Dp4 = [cos(ang4) sin(ang4)];
    kAct = find(opt.tiltMaxNode < deg2rad(178));
    A4 = spalloc(numel(kAct)*nP4, nz, numel(kAct)*nP4*2);  b4 = zeros(numel(kAct)*nP4,1);  r4 = 0;
    for ii = 1:numel(kAct)
        k = kAct(ii);
        rT4 = sqrt((1-cos(opt.tiltMaxNode(k)))/2);
        A4(r4+(1:nP4), ix.x(9,k))  = Dp4(:,1)*Dx(9);
        A4(r4+(1:nP4), ix.x(10,k)) = Dp4(:,2)*Dx(10);
        b4(r4+(1:nP4)) = rT4;
        r4 = r4 + nP4;
    end
    A2 = [A2; A4(1:r4,:)];  b2 = [b2; b4(1:r4)];
end

%% --- 空力降下フェーズの姿勢保持 (論文 2.2.1: フラップで抗力最大姿勢を維持) ---
%% ベリーフロップ姿勢からの逸脱を箱制約で抑える. 入れないと機体が寝て揚力で
%% 水平に流れ, 転回前に水平速度 30 m/s が溜まる.
if isfield(opt,'bellyHold') && opt.bellyHold > 0
    qRef = opt.qBelly(:);
    for k = 1:N+1
        kk = min(k,N);
        if opt.phase(kk) == 1
            for i = 7:10
                c0 = qRef(i-6)/Dx(i);
                lb(ix.x(i,k)) = max(lb(ix.x(i,k)), c0 - opt.bellyHold);
                ub(ix.x(i,k)) = min(ub(ix.x(i,k)), c0 + opt.bellyHold);
            end
        end
    end
end

prob = struct('P',P,'q',q,'G',G,'g',g,'A',A2,'b',b2,'lb',lb,'ub',ub);
end









