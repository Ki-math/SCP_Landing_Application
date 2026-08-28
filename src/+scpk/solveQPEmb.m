function [z,status,iters,resPri,resDua,w] = solveQPEmb(P,q,G,g,A,b,lb,ub,opt,z0,w0) %#codegen
%SOLVEQPEMB  箱制約付き凸QPの PIPG (組み込み/コード生成用).
%
%   [Z,STATUS,ITERS,RESPRI,RESDUA,W] = SOLVEQPEMB(P,q,G,g,A,b,LB,UB,OPT,Z0,W0)
%
%   scpk.solveQP と同一アルゴリズム. コード生成の制約に合わせて:
%     - ステータスは int32 のコード (0 maxIter / 1 converged /
%       2 primalInfeasible / 3 dualInfeasible / 4 numericalFailure)
%     - 文字列・可変構造体・isfield 分岐なし, 入力は密行列
%     - refSolver / logRes / 証明書ベクトルの出力なし (判定のみ)
%
%   OPT は scpk.qpOptions のサブセット (数値フィールドのみ):
%     maxIter, fixedIter(0/1), tolPri, tolDua, omega, rho, checkEvery,
%     powerIter, certAfter, certTol, certEps
%
%   See also SCPK.SOLVEQP, SCPK.QPOPTIONS
n = numel(q);
neq = size(G,1);  nin = size(A,1);  m = neq + nin;
C = [G; A];  d = [g; b];
z = z0(:);  w = w0(:);
status = int32(0);  iters = int32(0);  resPri = inf;  resDua = inf;

%% --- 入力検証 ---
if ~allF(P) || ~allF(q) || ~allF(G) || ~allF(g) || ~allF(A) || ~allF(b)
    status = int32(4);  return
end
for i = 1:n
    if isnan(lb(i)) || isnan(ub(i)) || lb(i) > ub(i), status = int32(4); return; end
end

%% --- ステップ幅 (べき乗法) ---
lam = 0;  x = ones(n,1)/sqrt(n);
for it = 1:opt.powerIter
    y = P*x;  lam = norm(y);
    if lam < eps, lam = 0; break; end
    x = y/lam;
end
sig = 0;  x = ones(n,1)/sqrt(n);
for it = 1:opt.powerIter
    y = C.'*(C*x);  sig = norm(y);
    if sig < eps, sig = 0; break; end
    x = y/sig;
end
al = 2/(lam + sqrt(lam^2 + 4*opt.omega*sig));
be = opt.omega*al;
if ~isfinite(al) || ~isfinite(be) || al <= 0
    z = min(ub, max(lb, z));  status = int32(4);  return
end

zb = z;  wb = w;  zPrev = z;  wPrev = w;
dzL = zeros(n,1);  dwL = zeros(m,1);
fixedIter = opt.fixedIter > 0;
status = int32(0);  iters = int32(opt.maxIter);
for k = 1:opt.maxIter
    zn = min(ub, max(lb, zb - al*(P*zb + q + C.'*wb)));
    wn = wb + be*(C*(2*zn - zb) - d);
    for i = neq+1:m, if wn(i) < 0, wn(i) = 0; end, end
    zb = (1-opt.rho)*zb + opt.rho*zn;
    wb = (1-opt.rho)*wb + opt.rho*wn;
    if mod(k, opt.checkEvery) == 0
        if any(~isfinite(zn)) || any(~isfinite(wn))
            status = int32(4);  iters = int32(k);
            z = min(ub, max(lb, zPrev));  return
        end
        dz = zn - zPrev;  dw = wn - wPrev;
        dzL = dz;  dwL = dw;  zPrev = zn;  wPrev = wn;
        zc = min(ub, max(lb, zb));
        [rp,rd] = resid(P,q,C,d,neq,m,lb,ub,zc,wb);
        if rp < opt.tolPri && rd < opt.tolDua && ~fixedIter
            status = int32(1);  iters = int32(k);
            resPri = rp;  resDua = rd;  z = zc;  w = wb;  return
        end
        if ~fixedIter && k >= opt.certAfter
            cs = certChk(P,q,C,d,neq,m,lb,ub,dz,dw,opt);
            if cs > 0
                status = int32(cs);  iters = int32(k);  z = zn;  w = wn;  return
            end
        end
    end
end
z = min(ub, max(lb, zb));  w = wb;
[rp,rd] = resid(P,q,C,d,neq,m,lb,ub,z,w);
resPri = rp;  resDua = rd;
if rp < opt.tolPri && rd < opt.tolDua
    status = int32(1);
elseif fixedIter
    cs = certChk(P,q,C,d,neq,m,lb,ub,dzL,dwL,opt);
    if cs > 0, status = int32(cs); end
end
end


function [rp,rd] = resid(P,q,C,d,neq,m,lb,ub,z,w)
r = C*z - d;
rpa = 0;
for i = 1:neq, if abs(r(i)) > rpa, rpa = abs(r(i)); end, end
for i = neq+1:m, if r(i) > rpa, rpa = r(i); end, end
sPri = max([norm(C*z,inf), norm(d,inf), 1]);
rp = rpa/sPri;
gr = P*z + q + C.'*w;
rda = norm(z - min(ub, max(lb, z - gr)), inf);
sDua = max([norm(P*z,inf), norm(q,inf), norm(C.'*w,inf), 1]);
rd = rda/sDua;
end


function cs = certChk(P,q,C,d,neq,m,lb,ub,dz,dw,opt)
%CERTCHK  実行不可能性の証明書判定. 0=なし, 2=primalInf, 3=dualInf.
cs = int32(0);
ndw = norm(dw,inf);
if ndw > opt.certTol
    v = C.'*dw;
    ok = true;
    for i = neq+1:m, if dw(i) < -opt.certTol*ndw, ok = false; break; end, end
    if ok
        sup = 0;  bad = false;
        for i = 1:numel(v)
            s = max(-v(i)*lb(i), -v(i)*ub(i));
            if ~isfinite(s), bad = true; break; end
            sup = sup + s;
        end
        if ~bad && (d.'*dw + sup) < -opt.certTol*ndw, cs = int32(2); return; end
    end
end
ndz = norm(dz,inf);
if ndz > opt.certTol
    Pd = P*dz;  Cd = C*dz;
    ok = norm(Pd,inf) <= opt.certEps*ndz;
    if ok
        for i = 1:neq, if abs(Cd(i)) > opt.certEps*ndz, ok = false; break; end, end
    end
    if ok
        for i = neq+1:m, if Cd(i) > opt.certEps*ndz, ok = false; break; end, end
    end
    if ok
        rec = true;
        for i = 1:numel(dz)
            if dz(i) >  opt.certEps*ndz && isfinite(ub(i)), rec = false; break; end
            if dz(i) < -opt.certEps*ndz && isfinite(lb(i)), rec = false; break; end
        end
        if rec && q.'*dz < -opt.certTol*ndz, cs = int32(3); end
    end
end
end


function tf = allF(X)
tf = ~any(~isfinite(X(:)));
end
