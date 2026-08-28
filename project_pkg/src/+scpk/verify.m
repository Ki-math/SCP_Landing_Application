function ver = verify(sol,cfg)
%VERIFY  平面6-DoF 解を真の非線形ダイナミクスで再積分して検証する.
%  制御は ZOH, 各区間を RK4 substep で積分.
sc = cfg.sc; N = size(sol.uhat,2); dt = sol.dt/sc.T; ns = 20; h = dt/ns;
x = sol.xhat(:,1); X = zeros(7,N+1); X(:,1) = x;
for k = 1:N
    u = sol.uhat(:,k); g = sol.ghat(k);
    for i = 1:ns
        k1 = scpk.dynamics(x,u,g,cfg); k2 = scpk.dynamics(x+h/2*k1,u,g,cfg);
        k3 = scpk.dynamics(x+h/2*k2,u,g,cfg); k4 = scpk.dynamics(x+h*k3,u,g,cfg);
        x = x + h/6*(k1+2*k2+2*k3+k4);
    end
    X(:,k+1) = x;
end
ver.h = X(1,:)*sc.L; ver.y = X(2,:)*sc.L;
ver.vh = X(3,:)*sc.V; ver.vy = X(4,:)*sc.V;
ver.theta = X(5,:); ver.omega = X(6,:)/sc.T; ver.m = X(7,:)*cfg.m0;
ver.dPos = hypot(ver.h - sol.h, ver.y - sol.y);
ver.dVel = hypot(ver.vh - sol.vh, ver.vy - sol.vy);
ver.dTheta = rad2deg(abs(ver.theta - sol.theta));
ver.maxPosErr = max(ver.dPos); ver.maxVelErr = max(ver.dVel); ver.maxThErr = max(ver.dTheta);
ver.term = [ver.h(end); ver.y(end); ver.vh(end); ver.vy(end); ver.theta(end); ver.omega(end)];
% 制約チェック (真の軌道上で)
Tm = hypot(sol.uhat(1,:),sol.uhat(2,:));
ver.throttle = Tm/cfg.Tmax;
ver.gimbal = atan2(sol.uhat(2,:),sol.uhat(1,:));
ver.lcGap = max(sol.ghat - Tm);
ver.propellant = ver.m(1) - ver.m(end);
end
