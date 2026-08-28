function [plan,info] = replan(x,t,plan0,cfg,opt)
%REPLAN  現在状態から接地までの軌道を引き直す (外部ソルバ非依存).
%
%   [PLAN,INFO] = REPLAN(X,T,PLAN0,CFG,OPT) は時刻 T の状態 X から接地条件
%   までの軌道を再計画する. 追従MPC は水平 1.6 s しか見ないため大きな偏差を
%   吸収できない. 終端までを見る計画を低頻度で解き直して余裕を配分する.
%
%   PLAN の時間軸は絶対時刻 (T から PLAN0.t(end) まで).
%   INFO.ok が false のときは PLAN0 をそのまま返す (悪い解を採用しない).
%
%   See also SCPK.PLANCONTINUATION, SCPK.TRACKSTEP, SCPK.REPLANOPTIONS
if nargin < 5 || isempty(opt), opt = scpk.replanOptions(); end
tRem = plan0.t(end) - t;
info = struct('tRemain',tRem,'reintErr',inf,'slack',inf,'time',0,'ok',false);
if tRem < opt.tMin, plan = plan0; return, end

xT = [cfg.hmin*cfg.sc.L; opt.yTarget; opt.vTouch; 0; 0; 0];

%% 節点数は残り時間に比例させ, 時間刻みを一定に保つ
Nfin = max(opt.Nmin, min(opt.Nmax, round(tRem/opt.dtNode)));
Nlad = unique(max(opt.Nmin, round(Nfin*opt.ladder)));

po = opt.plan;
po.engSchedFrac = max(0, min(1, (opt.tFlipEnd - t)/tRem));

%% ウォームスタート: 直前計画の残り区間を再サンプル
ref = [];
if opt.warmStart && ~isempty(plan0)
    ref = resampleRemaining(plan0, t, Nlad(1));
end

tic;
sol = scpk.planContinuation(x, xT, tRem, cfg, po, Nlad, ref);
info.time = toc;
ver = scpk.verify(sol,cfg);
info.reintErr = ver.maxPosErr;
info.slack = 0;
info.ok = ver.maxPosErr < opt.maxReintErr;
if ~info.ok, plan = plan0; return, end

plan = sol;
plan.t = sol.t + t;
end


function ref = resampleRemaining(plan0,t,N)
%RESAMPLEREMAINING  直前計画の [t, tf] 区間を N 節点に再サンプルする.
tk = linspace(t, plan0.t(end), N+1);
nu = size(plan0.uhat,2);  tu = plan0.t(1:nu);
tm = linspace(t, plan0.t(end), N+1);  tm = min(tm(1:N), tu(end));
ref.xhat = interp1(plan0.t, plan0.xhat.', tk,'linear').';
ref.uhat = interp1(tu, plan0.uhat.', tm,'linear').';
ref.ghat = reshape(interp1(tu, plan0.ghat.', tm,'linear'),1,N);
end
