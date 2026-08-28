function [sol,info] = plan(x0phys,xTphys,tf,cfg,opt,ref)
%PLAN  接地までの軌道を逐次凸計画で解く (外部ソルバ非依存).
%
%   [SOL,INFO] = PLAN(X0PHYS,XTPHYS,TF,CFG,OPT) は初期状態から終端条件まで
%   の軌道を求める. 部分問題は仮想制御と終端スラックにより常に実行可能で,
%   収束しない場合も実行可能な準最適軌道を返す.
%
%   X0PHYS = [rx; ry; vx; vy; theta; omega; m]  (物理単位)
%   XTPHYS = [rx; ry; vx; vy; theta; omega]     終端目標
%   REF    : ウォームスタート用の前回解 (省略可)
%
%   OPT.engSched に基数スケジュール (1xN) を与える. 省略時は全区間 cfg.nEng.
%
%   See also SCPK.BUILDPLAN, SCPK.SOLVEQP, SCPK.PRECONDITION
if nargin < 5 || isempty(opt), opt = scpk.planOptions(); end
if nargin < 6, ref = []; end
sc = cfg.sc; nx = 7; nu = 3;
sx = [sc.L;sc.L;sc.V;sc.V;1;1/sc.T;cfg.m0];
x0 = x0phys(:)./sx;  xT = xTphys(1:6);
N  = opt.N;  dt = (tf/sc.T)/N;
if isfield(opt,'engSched') && ~isempty(opt.engSched), eng = opt.engSched;
else, eng = cfg.nEng*ones(1,N); end

%% --- 初期線形化点 ---
if ~isempty(ref)
    so = linspace(0,1,size(ref.xhat,2)).'; sn = linspace(0,1,N+1).';
    xl = interp1(so, ref.xhat.', sn,'linear','extrap').';
    su = linspace(0,1,size(ref.uhat,2)).'; sm = linspace(0,1,N).';
    ul = interp1(su, ref.uhat.', sm,'linear','extrap').';
    gl = reshape(interp1(su, ref.ghat.', sm,'linear','extrap'),1,N);
    if size(ul,1) ~= nu, ul = ul.'; end
else
    xl = zeros(nx,N+1);
    xTn = [xT(1:2)/sc.L; xT(3:4)/sc.V; xT(5); xT(6)*sc.T];
    for i = 1:6, xl(i,:) = linspace(x0(i), xTn(i), N+1); end
    xl(7,:) = linspace(x0(7), x0(7)*0.95, N+1);
    ul = repmat([cfg.Tmin;0;0],1,N);  gl = cfg.Tmin*ones(1,N);
end
xl(:,1) = x0;

info = struct('iters',zeros(1,opt.maxIter),'primal',zeros(1,opt.maxIter), ...
              'step',zeros(1,opt.maxIter),'nIter',0,'time',0, ...
              'virtCtrl',zeros(1,opt.maxIter));
info.qpStatus = repmat({''},1,opt.maxIter);   % cell はここで別に持つ
tic;  z0 = [];
for it = 1:opt.maxIter
    [prob,ix,D] = scpk.buildPlan(x0,xT,xl,ul,gl,eng,dt,cfg,opt);
    [probS,S]   = scpk.precondition(prob);
    [zh,qi]     = scpk.solveQP(probS, opt.qp, z0);
    z  = S.col .* zh;  z0 = zh;
    xs = reshape(z(ix.x(:)),nx,N+1) .* D.x;
    us = reshape(z(ix.u(:)),nu,N)   .* D.u;
    gs = reshape(z(ix.g),1,N)       .* D.g;
    step = max(max(abs(xs - xl)./D.x));
    xl = xs; ul = us; gl = gs;
    info.iters(it)=qi.iters; info.primal(it)=qi.primal; info.step(it)=step; info.nIter=it;
    info.qpStatus{it} = qi.status;
    info.virtCtrl(it) = sum(max(0,z(ix.vp(:)))) + sum(max(0,z(ix.vm(:))));
    if opt.verbose
        fprintf('  it %2d: step=%9.3e primal=%9.3e (%d反復)\\n', it, step, qi.primal, qi.iters);
    end
    if step < opt.tolStep, break; end
end
info.time = toc;

%% --- 物理単位へ ---
sol.t = (0:N)*dt*sc.T;
sol.h = xs(1,:)*sc.L;  sol.y = xs(2,:)*sc.L;
sol.vh = xs(3,:)*sc.V; sol.vy = xs(4,:)*sc.V;
sol.theta = xs(5,:);   sol.omega = xs(6,:)/sc.T;
sol.m = xs(7,:)*cfg.m0;
sol.xhat = xs; sol.uhat = us; sol.ghat = gs;
sol.Tmag = hypot(us(1,:),us(2,:))*cfg.Fs;
sol.gimbal = atan2(us(2,:),us(1,:));
sol.throttle = sol.Tmag./(eng*cfg.veh.thrustPerEng);
sol.engSched = eng;  sol.tf = tf;  sol.dt = dt*sc.T;
sol.propellant = sol.m(1) - sol.m(end);
sol.qpStatus = info.qpStatus(1:info.nIter);
sol.virtCtrl = info.virtCtrl(info.nIter);
end


