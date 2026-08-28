function [prob,S] = precondition(prob,nIter)
%PRECONDITION  Ruiz 平衡化による対角前処理.
%
%   [PROB2,S] = PRECONDITION(PROB) は制約行列の行・列ノルムを 1 に近づける
%   対角スケーリングを施した問題 PROB2 と, 元に戻すための係数 S を返す.
%
%   一次法の収束は制約作用素のノルムに支配されるため, 行ごとのスケール差が
%   あると収束しない. OSQP や cvxpygen が既定で入れているのと同じ処理.
%
%   変数変換:  z = S.col .* zhat
%   復元    :  z = S.col .* zhat,  双対は S.rowE / S.rowI で割る
if nargin < 2 || isempty(nIter), nIter = 15; end
n = numel(prob.q);
neq = size(prob.G,1);  nin = size(prob.A,1);

%% --- 高速経路: C化したスケール計算 (ruiz_mex). 数学は下の MATLAB 実装と同一.
%% スケール係数だけ mex で求め, 疎行列への適用は1回で済ませる (15回 -> 1回).
if exist('ruiz_mex','file') == 3 && nnz(prob.P) == nnz(diag(diag(prob.P)))
    C0 = [prob.G; prob.A];  m0 = size(C0,1);
    [colv, rowAcc, cs] = ruiz_mex(C0, full(diag(prob.P)), nIter);
    Dc = spdiags(colv, 0, n, n);
    C1 = spdiags(1./rowAcc, 0, m0, m0) * C0 * Dc;
    prob.P = cs*(Dc*prob.P*Dc);
    prob.q = cs*(prob.q.*colv);
    prob.G = C1(1:neq,:);   prob.g = prob.g./rowAcc(1:neq);
    prob.A = C1(neq+1:end,:);  prob.b = prob.b./rowAcc(neq+1:end);
    prob.lb = prob.lb./colv;  prob.ub = prob.ub./colv;
    S.col = colv;  S.rowE = rowAcc(1:neq);  S.rowI = rowAcc(neq+1:end);  S.cost = cs;
    return
end

col = ones(n,1);  rowE = ones(max(neq,1),1);  rowI = ones(max(nin,1),1);
G = prob.G; A = prob.A; P = prob.P;
for i = 1:nIter
    C = [G; A];
    if isempty(C), break; end
    rn = sqrt(max(max(abs(C),[],2), 1e-12));
    cn = sqrt(max(max(abs([C; P]),[],1).', 1e-12));
    Dr = spdiags(1./rn,0,numel(rn),numel(rn));
    Dc = spdiags(1./cn,0,n,n);
    C = Dr*C*Dc;  P = Dc*P*Dc;
    G = C(1:neq,:);  A = C(neq+1:end,:);
    col = col./cn;
    if neq > 0, rowE = rowE.*rn(1:neq); end
    if nin > 0, rowI = rowI.*rn(neq+1:end); end
end
%% コスト全体のスケール (P の対角最大を 1 に)
cs = 1/max(max(abs(diag(P))),1e-12);
prob.P = cs*P;
prob.q = cs*(prob.q.*col);
prob.G = G;  prob.g = prob.g./rowE;
prob.A = A;  prob.b = prob.b./rowI;
prob.lb = prob.lb./col;  prob.ub = prob.ub./col;
S.col = col;  S.rowE = rowE;  S.rowI = rowI;  S.cost = cs;
end
