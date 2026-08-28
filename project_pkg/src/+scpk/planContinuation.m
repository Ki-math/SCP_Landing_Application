function [sol,info] = planContinuation(x0,xT,tf,cfg,opt,Nladder,ref0)
%PLANCONTINUATION  離散化を段階的に細かくしながら軌道を計画する.
%
%   [SOL,INFO] = PLANCONTINUATION(X0,XT,TF,CFG,OPT,NLADDER,REF0)
%
%   90deg のフリップを含む問題では直線補間の初期推測がダイナミクスから大きく
%   外れ, 細かい離散化では悪い局所解に閉じ込められる. 粗い離散化で解いてから
%   順に引き継ぐと同じ問題が解ける. 計算も速い.
%
%   NLADDER : 節点数の段階 (既定 [10 15 25])
%   REF0    : 最初の段のウォームスタート (省略可)
if nargin < 6 || isempty(Nladder), Nladder = [10 15 25]; end
if nargin < 7, ref0 = []; end
ref = ref0;  info = struct('N',{},'nIter',{},'step',{},'reint',{},'time',{});
for k = 1:numel(Nladder)
    o = opt;  o.N = Nladder(k);
    if isfield(opt,'engSchedFrac') && ~isempty(opt.engSchedFrac)
        nF = round(opt.engSchedFrac*o.N);
        o.engSched = [3*ones(1,nF), 2*ones(1,o.N-nF)];
    end
    [sol,si] = scpk.plan(x0,xT,tf,cfg,o,ref);
    ver = scpk.verify(sol,cfg);
    info(k).N=o.N; info(k).nIter=si.nIter; info(k).step=si.step(si.nIter);
    info(k).reint=ver.maxPosErr; info(k).time=si.time;
    if isfield(opt,'verbose') && opt.verbose
        fprintf('  [cont] N=%3d %2d反復 %5.2fs step=%8.2e 再積分%7.2f m\n', ...
                o.N, si.nIter, si.time, info(k).step, info(k).reint);
    end
    ref = sol;
end
sol.contInfo = info;
end
