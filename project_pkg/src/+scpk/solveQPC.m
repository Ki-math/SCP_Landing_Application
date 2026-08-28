function [z,info] = solveQPC(prob,opt,z0,w0)
%SOLVEQPC  手書きC++実装 (pipg_mex) を solveQP と同じインターフェースで呼ぶ.
%
%   [Z,INFO] = SOLVEQPC(PROB,OPT,Z0,W0)
%
%   scpk.solveQP と同一の問題形式・同一の判定基準. コスト行列 P は対角である
%   こと (計画QP・追従QPともに対角. 非対角なら solveQP を使う).
%
%   事前に drivers/cpp/buildPIPG を実行して pipg_mex をビルドしておくこと.
%
%   See also SCPK.SOLVEQP, BUILDPIPG
if nargin < 2 || isempty(opt), opt = scpk.qpOptions(); end
n = numel(prob.q);
C = [prob.G; prob.A];
d = [prob.g; prob.b];
neq = size(prob.G,1);
if nargin < 3 || isempty(z0), z0 = zeros(n,1); end
if nargin < 4 || isempty(w0), w0 = zeros(size(C,1),1); end
Pd = full(diag(prob.P));
eo = struct('maxIter',opt.maxIter, 'fixedIter',double(opt.fixedIter), ...
    'tolPri',opt.tolPri, 'tolDua',opt.tolDua, 'omega',opt.omega, 'rho',opt.rho, ...
    'checkEvery',opt.checkEvery, 'powerIter',opt.powerIter, ...
    'certAfter',opt.certAfter, 'certTol',opt.certTol, 'certEps',opt.certEps);
[z,st,it,rp,rd,w] = pipg_mex(Pd, full(prob.q), sparse(C), full(d), neq, ...
                             full(prob.lb), full(prob.ub), eo, full(z0(:)), full(w0(:)));
names = {'maxIter','converged','primalInfeasible','dualInfeasible','numericalFailure'};
info = struct('status',names{st+1}, 'iters',it, 'resPri',rp, 'resDua',rd, ...
              'resPriAbs',rp, 'resDuaAbs',rd, 'cost',0.5*(z.'*(prob.P*z))+prob.q.'*z, ...
              'cert',[], 'converged',st==1, 'w',w, 'primal',rp);
end
