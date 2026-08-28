function out = codegenBuild()
%CODEGENBUILD  計画buildのホットループ (linDisc6All) の C 生成 + 検証 + 計測.
%
%   MATLAB Coder で scpk.linDisc6All を MEX 化 (MinGW で実コンパイル).
%   buildPlan6 は linDisc6All_mex を自動検出して使う (単一ソース).
%   lib 生成も行い BLAS 残存を grep で確認する.
%
%   See also SCPK.LINDISC6ALL, SCPK.BUILDPLAN6
here = fileparts(mfilename('fullpath'));  proj = fileparts(here);
cpp = fullfile(proj,'src','cpp');
addpath(fullfile(proj,'src'), cpp);
cd(cpp);
cfg = scpk.model6();

%% --- 型定義 (可変サイズ: N<=200, フェーズ<=8) ---
xlT  = coder.typeof(0, [14 201], [0 1]);
ulT  = coder.typeof(0, [7 200], [0 1]);
sigT = coder.typeof(0, [1 8], [0 1]);
phT  = coder.typeof(0, [1 200], [0 1]);
dtT  = coder.typeof(0, [1 200], [0 1]);
cfgT = coder.typeof(cfg);
args = {xlT, ulT, sigT, phT, dtT, cfgT};

%% --- 1. MEX 生成 (実コンパイル) ---
mc = coder.config('mex');
codegen('-config', mc, 'scpk.linDisc6All', '-args', args, ...
        '-d', fullfile(cpp,'codegen_build_mex'), '-o', 'linDisc6All_mex');
fprintf('MEX 生成 OK\n');

%% --- 2. lib 生成 + BLAS grep ---
lc = coder.config('lib');  lc.EnableOpenMP = false;
outdir = fullfile(cpp,'codegen_build_lib');
codegen('-config', lc, 'scpk.linDisc6All', '-args', args, '-d', outdir, '-o', 'linDisc6All_lib');
cf = [dir(fullfile(outdir,'**','*.c')); dir(fullfile(outdir,'**','*.h'))];
hits = {};
for i = 1:numel(cf)
    txt = fileread(fullfile(cf(i).folder, cf(i).name));
    if ~isempty(regexpi(txt,'dgemm|dgemv|cblas|xgemm|xgemv','once')), hits{end+1}=cf(i).name; end %#ok<AGROW>
end
fprintf('lib 生成 OK: BLAS残存 %d件 / %dファイル\n', numel(hits), numel(cf));

%% --- 3. 等価性 + 計測 ---
S = load(fullfile(proj,'results','landing_vert.mat'));
sol = S.sol;  opt = S.opt;  sc = cfg.sc;
dtv = arrayfun(@(j) 1/sum(opt.phase==j), opt.phase);
sigl = sol.sigma/sc.T;  ph = double(opt.phase);
nR = 7;  tM = zeros(1,nR);  tX = zeros(1,nR);
for r = 1:nR
    t1=tic; [A1,B1,S1,c1] = scpk.linDisc6All(sol.xhat,sol.uhat,sigl,ph,dtv,cfg); tM(r)=toc(t1);
    t2=tic; [A2,B2,S2,c2] = linDisc6All_mex(sol.xhat,sol.uhat,sigl,ph,dtv,cfg);  tX(r)=toc(t2);
end
dmax = max([max(abs(A1(:)-A2(:))), max(abs(B1(:)-B2(:))), max(abs(S1(:)-S2(:))), max(abs(c1(:)-c2(:)))]);
fprintf('等価性: max diff = %.2e\n', dmax);
fprintf('線形化+離散化: MATLAB %.1f ms -> MEX %.1f ms (%.1fx)\n', ...
    median(tM)*1e3, median(tX)*1e3, median(tM)/median(tX));

out = struct('tMatlab',median(tM),'tMex',median(tX),'dmax',dmax,'blasHits',{hits});
save(fullfile(proj,'results','codegenBuild.mat'),'-struct','out');
fprintf('保存: results/codegenBuild.mat\n');
fp = mexFingerprint();  save(fullfile(proj,'results','mex_fingerprint.mat'),'fp'); %#ok<NASGU>

end
