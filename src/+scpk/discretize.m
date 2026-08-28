function [Ad,Bd,cd] = discretize(A,B,c,dt,nTerm)
%DISCRETIZE  線形時変系を ZOH 離散化する (expm 非依存).
%
%   [AD,BD,CD] = DISCRETIZE(A,B,C,DT) は連続系
%       xdot = A*x + B*u + c
%   を刻み DT で ZOH 離散化し, x(k+1) = AD*x(k) + BD*u(k) + CD を返す.
%
%   行列指数を打ち切り級数で評価する:
%       AD = sum_{i=0..N} (A*dt)^i / i!
%       Phi = sum_{i=0..N} (A*dt)^i /(i+1)!   ->  BD = dt*Phi*B,  CD = dt*Phi*c
%   expm はコード生成できるが重く, 組み込みでは固定次数の級数で足りる.
%   NTERM は既定 8 (dt*||A|| < 1 なら十分な精度).
if nargin < 5 || isempty(nTerm), nTerm = 8; end
n = size(A,1);
M = A*dt;
Ad  = eye(n);   %% sum M^i/i!
Phi = eye(n);   %% sum M^i/(i+1)!
Mp  = eye(n);
for i = 1:nTerm
    Mp = Mp*M/i;
    Ad = Ad + Mp;
    Phi = Phi + Mp/(i+1);
end
Bd = dt*(Phi*B);
cd = dt*(Phi*c(:));
end
