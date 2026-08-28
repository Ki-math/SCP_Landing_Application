function dbgWindSens()
%DBGWINDSENS  一時デバッグ: 風あり計画の Ty 感度チェック (非線形伝播).
proj = fileparts(fileparts(mfilename('fullpath')));
S2 = load(fullfile(proj,'results','landing_falcon9.mat'));
sol = S2.sol;  cfg = S2.cfg;  sc = cfg.sc;
u2 = sol.uhat;  k2 = find(sol.phase==2);
u2(2,k2) = u2(2,k2) - 0.3;
x1 = prop(sol, sol.uhat, cfg);
x2 = prop(sol, u2, cfg);
fprintf('終端CR: 元%.1fm -> Ty-0.3で%.1fm (応答%.1fm)\n', ...
    x1(2)*sc.L, x2(2)*sc.L, (x2(2)-x1(2))*sc.L);
end

function x = prop(sol, uu, cfg)
sc = cfg.sc;  N = numel(sol.phase);
x = [sol.r(:,1)/sc.L; sol.v(:,1)/sc.V; sol.q(:,1); sol.w(:,1)*sc.T; sol.m(1)/cfg.m0];
for k = 1:N
    dtk = (sol.t(k+1)-sol.t(k))/sc.T;  u = uu(:,k);
    for s = 1:4
        h = dtk/4;
        k1 = scpk.dynamics6(x,u,cfg);          k2 = scpk.dynamics6(x+0.5*h*k1,u,cfg);
        k3 = scpk.dynamics6(x+0.5*h*k2,u,cfg); k4 = scpk.dynamics6(x+h*k3,u,cfg);
        x = x + h/6*(k1+2*k2+2*k3+k4);  x(7:10) = x(7:10)/norm(x(7:10));
    end
end
end
