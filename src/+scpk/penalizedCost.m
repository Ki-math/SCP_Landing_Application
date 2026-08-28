function [J,defect] = penalizedCost(xs,us,xT,cfg,opt,dt)
%PENALIZEDCOST  真の非線形ダイナミクスで評価した罰則付きコスト.
%
%   [J,DEFECT] = PENALIZEDCOST(XS,US,XT,CFG,OPT,DT) は解 (XS,US) を各区間で
%   真の非線形モデルにより伝播し, 区間ごとの不整合 (defect) と終端条件違反を
%   L1 で罰したコストを返す.
%
%   信頼領域の適応制御では, 部分問題が予測した改善量と実際の改善量の比
%   rho = (実際) / (予測) を見る. その「実際」を測るのがこの関数.
%   線形化の中だけで評価すると, 予測と実際の乖離が分からない.
nx = 14;  N = size(us,2);
defect = 0;
for k = 1:N
    x = xs(:,k);  u = us(:,k);
    if isscalar(dt), h = dt/opt.nSub; else, h = dt(k)/opt.nSub; end
    for j = 1:opt.nSub
        k1 = scpk.dynamics6(x,u,cfg);         k2 = scpk.dynamics6(x+h/2*k1,u,cfg);
        k3 = scpk.dynamics6(x+h/2*k2,u,cfg);  k4 = scpk.dynamics6(x+h*k3,u,cfg);
        x  = x + h/6*(k1+2*k2+2*k3+k4);
    end
    defect = defect + sum(abs((xs(:,k+1) - x)./opt.dScale));
end
iT = [1 2 3, 4 5 6, 8 9 10, 11 12 13];
termViol = sum(abs((xs(iT,N+1) - xT(:))./opt.dScale(iT)));
J = -opt.wFuel*xs(nx,N+1)/opt.dScale(nx) + opt.lamVC*defect + opt.lamTerm*termViol;
end
