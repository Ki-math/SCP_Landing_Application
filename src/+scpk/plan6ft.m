function [sol,info] = plan6ft(x0phys,xTphys,sig0,cfg,opt,ref)
%PLAN6FT  自由終端時刻の6自由度 多フェーズ着陸軌道を SCvx で解く.
%
%   [SOL,INFO] = PLAN6FT(X0PHYS,XTPHYS,SIG0,CFG,OPT,REF)
%
%   各フェーズの飛行時間を時間膨張係数 sigma_j として最適化する. 正規化時刻
%   tau in [0,1] で x' = sigma_j*f(x,u) と書き, sigma を追加制御として線形化
%   すると既存の離散化がそのまま使える.
%
%   SIG0   各フェーズの初期推定時間 [s] (1 x nPhase)
%   OPT.phase   各節点が属するフェーズ番号 (1 x N)
%   OPT.engSched 各節点のエンジン基数 (1 x N)
%
%   フェーズ構成 (参考文献の Fig.1 に対応)
%     1 空力降下   エンジン停止, フラップで姿勢保持
%     2 転回       3基点火, TVC で機体を垂直へ
%     3 垂直整列   1基, 転回中に生じた水平速度を打ち消す
%     4 精密着陸   1基, 残速度を消して着地
%
%   参考: Lee, Jung & Lee, Int. J. Aeronaut. Space Sci. 26:1890 (2025)
if nargin < 5 || isempty(opt), opt = scpk.planOptions6(); end
if nargin < 6, ref = []; end
sc = cfg.sc;  nx = 14;  nu = 7;
sx = [repmat(sc.L,3,1); repmat(sc.V,3,1); ones(4,1); repmat(1/sc.T,3,1); cfg.m0];
x0 = x0phys(:)./sx;  xT = xTphys(:);
ph = opt.phase(:).';  N = numel(ph);  nPh = max(ph);
eng = opt.engSched(:).';

%% 正規化時刻の刻み: 各フェーズを等分割 (dtau = 1/nNode_j)
dtv = zeros(1,N);
for j = 1:nPh, dtv(ph==j) = 1/sum(ph==j); end
sigl = sig0(:).'/sc.T;                     %% 無次元時間

%% --- 初期線形化点 ---
if ~isempty(ref)
    so = linspace(0,1,size(ref.xhat,2)).';  sn = linspace(0,1,N+1).';
    xl = interp1(so, ref.xhat.', sn,'linear','extrap').';
    su = linspace(0,1,size(ref.uhat,2)).';  sm = linspace(0,1,N).';
    ul = interp1(su, ref.uhat.', sm,'linear','extrap').';
    if size(ul,1) ~= nu, ul = ul.'; end
    gl = reshape(interp1(su, ref.ghat.', sm,'linear','extrap'),1,N);
    if isfield(ref,'sigma'), sigl = ref.sigma/sc.T; end
else
    %% 初期線形化点: 直線補間ではなく, 名目制御で実際に伝播した軌道を使う.
    %% 直線補間の速度プロファイルは実弾道と大きく違い, nu が速度行に残り続ける
    %% (SCP が時間 sigma を伸ばして辻褄を合わせようとする).
    ul = zeros(nu,N);  gl = zeros(1,N);
    for k = 1:N
        if eng(k) > 0
            ul(1,k) = eng(k)*cfg.Tmin1;  gl(k) = eng(k)*cfg.Tmin1;
        end
    end
    xl = zeros(nx,N+1);  xl(:,1) = x0;
    for k = 1:N
        h = dtv(k)*sigl(ph(k))/opt.nSubInit;  xk = xl(:,k);
        for j = 1:opt.nSubInit
            k1 = scpk.dynamics6(xk,ul(:,k),cfg);         k2 = scpk.dynamics6(xk+h/2*k1,ul(:,k),cfg);
            k3 = scpk.dynamics6(xk+h/2*k2,ul(:,k),cfg);  k4 = scpk.dynamics6(xk+h*k3,ul(:,k),cfg);
            xk = xk + h/6*(k1+2*k2+2*k3+k4);
        end
        xk(7:10) = xk(7:10)/norm(xk(7:10));
        xl(:,k+1) = xk;
    end
    %% 初期推測を高度下限でクランプする. 伝播が地面を突き抜けると, 固定した
    %% 下限とトラストリージョンの交差が空になり QP が実行不可能になる.
    hFloorInit = cfg.hmin - opt.hMargin/sc.L;
    xl(1,:) = max(xl(1,:), hFloorInit);
    %% 姿勢だけは目標へ向かう補間で上書き (伝播ではベリーのまま回らない)
    %% 姿勢の初期推測: 空力降下フェーズはベリーフロップを保持し, 転回以降で
    %% 垂直へ補間する. 全区間で一様に補間すると降下中に機体が寝て, 姿勢保持
    %% 制約と矛盾して QP が実行不可能になる.
    kFlip = find(ph >= 2, 1);
    if isempty(kFlip), kFlip = 1; end
    for k = 0:N
        if k+1 <= kFlip
            xl(7:10,k+1) = x0(7:10);
        else
            s = (k+1-kFlip)/max(N+1-kFlip,1);
            xl(7:10,k+1) = slerpLocal(x0(7:10), [1;0;0;0], s);
        end
    end
end
xl(:,1) = x0;

%% 計装: 初回線形化点(伝播した初期推測)をそのまま返す (診断用, ソルブしない)
if isfield(opt,'captureInit') && opt.captureInit
    sol = struct('xhat',xl,'uhat',ul,'ghat',gl,'sigma',sigl*sc.T, ...
                 'x0nd',x0,'xT',xT,'dtv',dtv);
    info = struct('init',true,'xl',xl,'ul',ul,'gl',gl,'sigl',sigl);
    return
end

info = struct('iters',zeros(1,opt.maxIter),'primal',zeros(1,opt.maxIter), ...
              'step',zeros(1,opt.maxIter),'virtCtrl',zeros(1,opt.maxIter), ...
              'nIter',0,'time',0);
info.qpStatus = repmat({''},1,opt.maxIter);
info.sigma = zeros(opt.maxIter,nPh);
info.qpTime = zeros(1,opt.maxIter);      %% 計装: 各外側反復の solveQP 実時間 [s]
info.buildTime = zeros(1,opt.maxIter);   %% 計装: 各外側反復の build+precondition 実時間 [s]
tic;  z0 = [];  wTR = opt.wTR;  optI = opt;
for it = 1:opt.maxIter
    %% トラストリージョンを反復とともに縮める. 一定幅だと境界に張り付いて
    %% 等速で動き続け, step が下がらない (sigma が 22 s まで膨張した).
    sh = opt.trShrinkRate^(it-1);
    optI.trX   = max(opt.trXmin,   opt.trX*sh);
    optI.trU   = max(opt.trUmin,   opt.trU*sh);
    optI.trSig = max(opt.trSigMin, opt.trSig*sh);
    tB = tic;
    [prob,ix,D] = scpk.buildPlan6(x0,xT,xl,ul,gl,sigl,eng,dtv,cfg,optI);
    [probS,S]   = scpk.precondition(prob);
    info.buildTime(it) = toc(tB);
    tQ = tic;
    if isfield(opt,'useCpp') && opt.useCpp && exist('pipg_mex','file') == 3
        [zh,qi] = scpk.solveQPC(probS, opt.qp, z0);   %% 手書きC++ (等価性検証済み)
    else
        [zh,qi] = scpk.solveQP(probS, opt.qp, z0);
    end
    info.qpTime(it) = toc(tQ);
    z  = S.col .* zh;  z0 = zh;
    xs = reshape(z(ix.x(:)),nx,N+1) .* D.x;
    us = reshape(z(ix.u(:)),nu,N)   .* D.u;
    gs = reshape(z(ix.g),1,N)       .* D.g;
    ss = reshape(z(ix.sig),1,nPh)   .* D.sig;
    for k = 1:N+1
        nq = norm(xs(7:10,k));  if nq > eps, xs(7:10,k) = xs(7:10,k)/nq; end
    end
    step = max([max(max(abs(xs - xl)./D.x)), max(abs(ss - sigl)/D.sig)]);
    xl = xs;  ul = us;  gl = gs;  sigl = ss;
    info.iters(it)=qi.iters; info.primal(it)=qi.primal; info.step(it)=step; info.nIter=it;
    info.qpStatus{it} = qi.status;
    info.virtCtrl(it) = sum(max(0,z(ix.vp(:)))) + sum(max(0,z(ix.vm(:))));
    info.sigma(it,:) = ss*sc.T;
    if opt.verbose
        fprintf('  it %2d: step=%9.3e nu=%9.3e sigma=[%s] s (%s)\n', it, step, ...
                info.virtCtrl(it), num2str(ss*sc.T,'%6.2f '), qi.status);
    end
    if step < opt.tolStep, break; end
end
info.time = toc;

%% --- 物理単位へ ---
sigPhys = sigl*sc.T;
tGrid = zeros(1,N+1);  tAcc = 0;
for k = 1:N
    tAcc = tAcc + dtv(k)*sigPhys(ph(k));
    tGrid(k+1) = tAcc;
end
sol.t = tGrid;  sol.sigma = sigPhys;  sol.tf = sum(sigPhys);
sol.r = xs(1:3,:)*sc.L;   sol.v = xs(4:6,:)*sc.V;
sol.q = xs(7:10,:);       sol.w = xs(11:13,:)/sc.T;
sol.m = xs(14,:)*cfg.m0;
sol.xhat = xs;  sol.uhat = us;  sol.ghat = gs;
sol.T_B = us(1:3,:)*cfg.Fs;   sol.flap = us(4:7,:);
sol.Tmag = vecnorm(sol.T_B);
sol.throttle = sol.Tmag./max(eng,1)/cfg.veh.thrustPerEng;
sol.engSched = eng;  sol.phase = ph;  sol.dtau = dtv;
sol.propellant = sol.m(1) - sol.m(end);
sol.qpStatus = info.qpStatus(1:info.nIter);
sol.virtCtrl = info.virtCtrl(info.nIter);
end


function q = slerpLocal(q1,q2,s)
d = q1.'*q2;
if d < 0, q2 = -q2; d = -d; end
if d > 0.9995, q = q1 + s*(q2-q1);
else, th = acos(d);  q = (sin((1-s)*th)*q1 + sin(s*th)*q2)/sin(th); end
q = q/norm(q);
end





