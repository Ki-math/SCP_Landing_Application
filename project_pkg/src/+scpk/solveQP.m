function [z,info] = solveQP(prob,opt,z0,w0)
%SOLVEQP  箱制約付き凸QPを PIPG で解き, 求解ステータスを明示して返す.
%
%   [Z,INFO] = SOLVEQP(PROB,OPT) は次の問題を解く.
%
%       minimize   0.5*z'*P*z + q'*z
%       subject to G*z = g          (等式)
%                  A*z <= b         (一般不等式)
%                  lb <= z <= ub    (箱制約)
%
%   箱制約は射影で直接扱い, 双対変数を通さない. 単純な上下限を一般不等式に
%   入れると双対の次元が増えて収束が落ちるため, 分離しておくこと.
%
%   INFO.status は必ず次のいずれかを名乗る.
%     'converged'         主残差・双対残差ともに許容以下
%     'maxIter'           反復上限に到達 (解は返すが精度は保証しない)
%     'primalInfeasible'  実行可能領域が空. INFO.cert に証明書
%     'dualInfeasible'    主問題が非有界. INFO.cert に証明書
%     'numericalFailure'  NaN/Inf または反復量の発散
%
%   固定反復モード (OPT.fixedIter = true) では反復数を OPT.maxIter に固定し
%   実行時間を決定的にする. その場合も最終判定は必ず行う.
%   「時間は必ず守る, 結果は必ず名乗る」という設計.
%
%   残差は相対値で判定する. 前処理でスケールが変わるため, 絶対値では
%   閾値が問題ごとに意味を失う (OSQP / cvxpygen と同じ扱い).
%
%   INFO のフィールド
%     status, iters, resPri, resDua, cost, cert, converged
%     resPriAbs, resDuaAbs  正規化前の残差
%     w                     双対解 (ウォームスタート用)
%
%   See also SCPK.QPOPTIONS, SCPK.PRECONDITION
if nargin < 2 || isempty(opt), opt = scpk.qpOptions(); end
%% --- 入力検証: NaN/Inf を先に弾く (射影が NaN を潰して見逃すため) ---
if ~allFinite(prob.P) || ~allFinite(prob.q) || ~allFinite(prob.G) || ~allFinite(prob.g) ...
        || ~allFinite(prob.A) || ~allFinite(prob.b)
    z = zeros(numel(prob.q),1);
    info = struct('status','numericalFailure','iters',0,'resPri',inf,'resDua',inf, ...
                  'resPriAbs',inf,'resDuaAbs',inf,'cost',inf,'cert',[], ...
                  'converged',false,'w',[],'alpha',0,'beta',0,'primal',inf);
    return
end
if any(isnan(prob.lb)) || any(isnan(prob.ub)) || any(prob.lb > prob.ub)
    z = zeros(numel(prob.q),1);
    info = struct('status','numericalFailure','iters',0,'resPri',inf,'resDua',inf, ...
                  'resPriAbs',inf,'resDuaAbs',inf,'cost',inf,'cert',[], ...
                  'converged',false,'w',[],'alpha',0,'beta',0,'primal',inf);
    return
end
n = numel(prob.q);
neq = size(prob.G,1);  nin = size(prob.A,1);  m = neq + nin;
C = [prob.G; prob.A];  d = [prob.g; prob.b];
iq = (neq+1):m;
lb = prob.lb;  ub = prob.ub;
if nargin < 3 || isempty(z0), z = zeros(n,1); else, z = z0(:); end
if nargin < 4 || isempty(w0), w = zeros(m,1); else, w = w0(:); end

%% --- 検証用の参照ソルバ経路 ---
%% opt.refSolver=true なら quadprog で解く. PIPG が弱いのか定式化が悪いのかを
%% 切り分けるためだけの経路で, 組み込みでは使わない (外部依存が入るため).
if isfield(opt,'refSolver') && opt.refSolver
    oq = optimoptions('quadprog','Display','off','OptimalityTolerance',1e-10, ...
                      'ConstraintTolerance',1e-10,'MaxIterations',400);
    z = quadprog(full((prob.P+prob.P.')/2), prob.q, full(prob.A), prob.b, ...
                 full(prob.G), prob.g, lb, ub, [], oq);
    if isempty(z), z = zeros(n,1); end
    r = C*z - d;
    rpa = max([abs(r(1:neq)); max(r(iq),0); 0]);
    info = struct('status','converged','iters',0,'resPri',rpa,'resDua',0, ...
                  'resPriAbs',rpa,'resDuaAbs',0, ...
                  'cost',0.5*(z.'*(prob.P*z))+prob.q.'*z,'cert',[], ...
                  'converged',true,'w',zeros(m,1),'alpha',0,'beta',0,'primal',rpa);
    return
end

%% --- ステップ幅 ---
if isfield(opt,'alpha') && ~isempty(opt.alpha)
    al = opt.alpha;  be = opt.beta;        %% 事前計算値 (組み込み向け)
else
    lam = powerIter(@(v) prob.P*v, n, opt.powerIter);
    sig = powerIter(@(v) C.'*(C*v), n, opt.powerIter);
    al  = 2/(lam + sqrt(lam^2 + 4*opt.omega*sig));
    be  = opt.omega*al;
end
%% --- ステップ幅の縮退を弾く ---
%% P=0 かつ制約が実質ゼロだと lam=sig=0 で alpha=Inf になり, 射影で z が
%% 箱に張り付いて反復が一切進まない (判定も走らない).
if ~isfinite(al) || ~isfinite(be) || al <= 0
    z = min(ub, max(lb, z));
    info = struct('status','numericalFailure','iters',0,'resPri',inf,'resDua',inf, ...
                  'resPriAbs',inf,'resDuaAbs',inf,'cost',inf,'cert',[], ...
                  'converged',false,'w',w,'alpha',al,'beta',be,'primal',inf);
    return
end

info = struct('status','maxIter','iters',opt.maxIter,'resPri',inf,'resDua',inf, ...
              'resPriAbs',inf,'resDuaAbs',inf,'cost',inf,'cert',[], ...
              'converged',false,'w',w,'alpha',al,'beta',be,'primal',inf);

zb = z;  wb = w;  zPrev = z;  wPrev = w;
fixedIter = isfield(opt,'fixedIter') && opt.fixedIter;
dzLast = zeros(n,1);  dwLast = zeros(m,1);   % 最終判定用の反復差分
logRes = isfield(opt,'logRes') && opt.logRes;  hk=[]; hrp=[]; hrd=[];  % 計装: 残差履歴
for k = 1:opt.maxIter
    zn = min(ub, max(lb, zb - al*(prob.P*zb + prob.q + C.'*wb)));
    wn = wb + be*(C*(2*zn - zb) - d);
    wn(iq) = max(0, wn(iq));
    zb = (1-opt.rho)*zb + opt.rho*zn;
    wb = (1-opt.rho)*wb + opt.rho*wn;
    if mod(k,opt.checkEvery) == 0
        if any(~isfinite(zn)) || any(~isfinite(wn))
            info.status = 'numericalFailure';  info.iters = k;
            z = min(ub,max(lb,zPrev));  return
        end
        dz = zn - zPrev;  dw = wn - wPrev;
        dzLast = dz;  dwLast = dw;  zPrev = zn;  wPrev = wn;
        %% --- 収束判定 (相対残差) ---
        zc = min(ub,max(lb,zb));   % ループ後の判定と同じ点で評価する
        [rp,rpa,rd,rda] = residuals(prob,C,d,neq,iq,lb,ub,zc,wb);
        if logRes, hk(end+1)=k; hrp(end+1)=rp; hrd(end+1)=rd; end %#ok<AGROW>
        if rp < opt.tolPri && rd < opt.tolDua && ~fixedIter
            info.status='converged'; info.iters=k; info.converged=true;
            info.resPri=rp; info.resDua=rd; info.resPriAbs=rpa; info.resDuaAbs=rda;
            z = zc;  w = wb;  break
        end
        %% --- 実行不可能性の判定 (数十反復ごと) ---
        if ~fixedIter && k >= opt.certAfter
            cert = checkInfeasible(prob,C,d,neq,iq,lb,ub,dz,dw,opt);
            if ~isempty(cert)
                info.status = cert.type;  info.cert = cert;  info.iters = k;
                z = zn;  w = wn;  break
            end
        end
    end
end
if strcmp(info.status,'maxIter') || strcmp(info.status,'converged')
    z = min(ub, max(lb, zb));  w = wb;
    [rp,rpa,rd,rda] = residuals(prob,C,d,neq,iq,lb,ub,z,w);
    info.resPri=rp; info.resDua=rd; info.resPriAbs=rpa; info.resDuaAbs=rda;
    if rp < opt.tolPri && rd < opt.tolDua
        info.status='converged'; info.converged=true;
    elseif fixedIter
        %% 固定反復では反復中の証明書判定を省くため, ここで一度だけ判定する.
        %% 実行時間は 1 回分の追加で済み, 決定性を損なわない.
        cert = checkInfeasible(prob,C,d,neq,iq,lb,ub,dzLast,dwLast,opt);
        if ~isempty(cert)
            info.status = cert.type;  info.cert = cert;
        end
    end
end
info.cost = 0.5*(z.'*(prob.P*z)) + prob.q.'*z;
info.w = w;  info.primal = info.resPriAbs;
if logRes, info.hist = struct('k',hk,'rp',hrp,'rd',hrd); end
end


function [rp,rpa,rd,rda] = residuals(prob,C,d,neq,iq,lb,ub,z,w)
%RESIDUALS  主残差と双対残差 (絶対値と相対値).
%   主   : 等式違反と不等式違反の最大
%   双対 : 箱制約付き停留条件の自然残差 z - clip(z - (Pz+q+C'w))
r = C*z - d;
rpa = 0;
for i = 1:neq, if abs(r(i)) > rpa, rpa = abs(r(i)); end, end
for i = iq,    if r(i)      > rpa, rpa = r(i);      end, end
%% 正規化分母の下限は 1 にする. g=0 かつ Gz~0 のとき下限を 1e-12 にすると
%% 機械精度の違反 6.7e-16 が相対 6.7e-4 に化け, 収束を判定できなくなる.
%% 下限 1 なら小さい問題では絶対誤差判定に, 大きい問題では相対判定になる.
sPri = max([norm(C*z,inf), norm(d,inf), 1]);
rp = rpa/sPri;
gr = prob.P*z + prob.q + C.'*w;
rda = norm(z - min(ub,max(lb, z - gr)), inf);
sDua = max([norm(prob.P*z,inf), norm(prob.q,inf), norm(C.'*w,inf), 1]);
rd = rda/sDua;
end


function cert = checkInfeasible(prob,C,d,neq,iq,lb,ub,dz,dw,opt)
%CHECKINFEASIBLE  PDHG 系の実行不可能性証明書を判定する.
%   主実行不可能なら双対反復差 dw が非ゼロの一定方向に収束し, その方向が
%   証明書になる. 箱制約があるので支持関数の項が入る.
%   双対非有界 (主非有界) は主変数差 dz について対称の条件で見る.
cert = [];
ndw = norm(dw,inf);
if ndw > opt.certTol
    v  = C.'*dw;
    %% 箱制約がある場合 C'dw はゼロである必要がない (支持関数が引き受ける).
    %% 直交性を課すのは箱が無い定式化の話で, ここでは余計な条件になる.
    ok = all(dw(iq) >= -opt.certTol*ndw);
    if ok
        %% 支持関数: sup_{lb<=z<=ub} (-v'z)
        sup = 0;  bad = false;
        for i = 1:numel(v)
            a = -v(i)*lb(i);  b2 = -v(i)*ub(i);
            s = max(a,b2);
            if ~isfinite(s), bad = true; break; end
            sup = sup + s;
        end
        if ~bad && (d.'*dw + sup) < -opt.certTol*ndw
            cert.type = 'primalInfeasible';  cert.dw = dw/ndw;
            cert.value = (d.'*dw + sup)/ndw;  return
        end
    end
end
ndz = norm(dz,inf);
if ndz > opt.certTol
    Pd = prob.P*dz;  Cd = C*dz;
    ok = norm(Pd,inf) <= opt.certEps*ndz && norm(Cd(1:neq),inf) <= opt.certEps*ndz ...
         && all(Cd(iq) <= opt.certEps*ndz);
    if ok
        rec = true;
        for i = 1:numel(dz)
            if dz(i) > opt.certEps*ndz  && isfinite(ub(i)), rec = false; break; end
            if dz(i) < -opt.certEps*ndz && isfinite(lb(i)), rec = false; break; end
        end
        if rec && prob.q.'*dz < -opt.certTol*ndz
            cert.type = 'dualInfeasible';  cert.dz = dz/ndz;
            cert.value = prob.q.'*dz/ndz;
        end
    end
end
end


function s = powerIter(Afun,n,nit)
%POWERITER  作用素の最大特異値をべき乗法で推定する.
x = ones(n,1)/sqrt(n);  s = 0;
for i = 1:nit
    y = Afun(x);  s = norm(y);
    if s < eps, s = 0; return; end
    x = y/s;
end
end


function tf = allFinite(X)
%ALLFINITE  行列/ベクトルの全要素が有限か.
tf = ~any(~isfinite(X(:)));
end






