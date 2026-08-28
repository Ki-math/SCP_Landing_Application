function out = runClosedLoop(plan0,cfg,opt,x0,dtc,ropt)
%RUNCLOSEDLOOP  誘導 (軌道計画 + 周期再計画 + 追従MPC) の閉ループ検証.
%
%   OUT = RUNCLOSEDLOOP(PLAN0,CFG,OPT,X0) は初期状態 X0 から接地までを
%   シミュレートする. 追従MPC は TRACKSTEP (外部ソルバ非依存) を使う.
%   プラント代理は平面6-DoF非線形モデル (DYNAMICS) の RK4 積分.
%
%   OUT = RUNCLOSEDLOOP(...,DTC,ROPT) は制御周期 DTC [s] と再計画設定 ROPT.
%   ROPT を省略すると再計画せず PLAN0 を固定参照として追従する.
%
%   See also SCPK.TRACKSTEP, REPLANTRAJECTORY
if nargin < 5 || isempty(dtc), dtc = 0.2; end
if nargin < 6, ropt = []; end
sc = cfg.sc; sx = [sc.L;sc.L;sc.V;sc.V;1;1/sc.T;cfg.m0];
plan = plan0; x = x0(:); t = 0; ns = ceil(plan0.t(end)/dtc);  out_touchdown = false;
X = zeros(ns+1,7); U = zeros(ns,3); C = zeros(ns,5); T = zeros(ns+1,1);
tq = zeros(ns,1); it = zeros(ns,1); pr = zeros(ns,1);
rp = struct('t',{},'reintErr',{},'slack',{},'time',{},'ok',{});
X(1,:) = x.'; tNext = 0; warm = [];
for k = 1:ns
    if t >= plan0.t(end) - 1e-6, ns = k-1; break; end
    if ~isempty(ropt) && t >= tNext - 1e-9
        [pn,inf1] = scpk.replan(x,t,plan,cfg,ropt);
        if inf1.ok, plan = pn; warm = []; end
        rp(end+1) = struct('t',t,'reintErr',inf1.reintErr,'slack',inf1.slack, ...
                           'time',inf1.time,'ok',inf1.ok); %#ok<AGROW>
        tNext = t + ropt.period;
    end
    [cmd,sol,inf2] = scpk.trackStep(x,t,plan,cfg,opt,warm);
    warm = sol; tq(k) = inf2.time; it(k) = inf2.iters; pr(k) = inf2.primal;
    u = sol.u(:,1); g = hypot(u(1),u(2));
    ck = cfg;
    if cmd.nEng >= 3, ck.cB = cfg.cBunit/3; else, ck.cB = cfg.cBunit; end
    xh = x./sx; h = (dtc/sc.T)/10;
    for j = 1:10
        a1=scpk.dynamics(xh,u,g,ck);        a2=scpk.dynamics(xh+h/2*a1,u,g,ck);
        a3=scpk.dynamics(xh+h/2*a2,u,g,ck); a4=scpk.dynamics(xh+h*a3,u,g,ck);
        xh = xh + h/6*(a1+2*a2+2*a3+a4);
    end
    xPrev = x;
    x = xh.*sx; t = t + dtc;
    %% --- 接地判定: 目標高度を下回った瞬間で打ち切る ---
    if x(1) <= cfg.hmin*cfg.sc.L
        f = (xPrev(1) - cfg.hmin*cfg.sc.L)/max(xPrev(1)-x(1),eps);
        x = xPrev + f*(x - xPrev);  t = t - dtc + f*dtc;
        X(k+1,:) = x.'; T(k+1) = t; U(k,:) = u.';
        C(k,:) = [cmd.theta, cmd.omega, cmd.thrust, cmd.nEng, cmd.df];
        ns = k; out_touchdown = true; break
    end
    X(k+1,:) = x.'; T(k+1) = t; U(k,:) = u.';
    C(k,:) = [cmd.theta, cmd.omega, cmd.thrust, cmd.nEng, cmd.df];
end
out.touchdown = out_touchdown;
out.t=T(1:ns+1); out.X=X(1:ns+1,:); out.U=U(1:ns,:); out.cmd=C(1:ns,:);
out.tq=tq(1:ns); out.iters=it(1:ns); out.primal=pr(1:ns); out.replan=rp; out.plan=plan;
out.h=out.X(:,1); out.y=out.X(:,2); out.vh=out.X(:,3); out.vy=out.X(:,4);
out.theta=out.X(:,5); out.omega=out.X(:,6); out.m=out.X(:,7);
out.Tmag=hypot(out.U(:,1),out.U(:,2))*cfg.Fs;
out.nEng=out.cmd(:,4);
out.throttle=out.Tmag./(out.nEng*cfg.veh.thrustPerEng);
tc=min(out.t,plan0.t(end));
out.errH=out.h-interp1(plan0.t,plan0.h,tc,'linear');
out.errY=out.y-interp1(plan0.t,plan0.y,tc,'linear');
out.errTh=out.theta-interp1(plan0.t,plan0.theta,tc,'linear');
end


