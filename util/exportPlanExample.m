function exportPlanExample(vehicle)
%EXPORTPLANEXAMPLE  計画/追従デモ用の実データCヘッダを生成する.
%
%   EXPORTPLANEXAMPLE()            Starship の計画解から生成 (既定)
%   EXPORTPLANEXAMPLE('falcon9')   Falcon9 の計画解から生成
%
%   codegen_planiter_lib/examples_data/plan_example_data.h を出力.
%   内容: scpk_planIterEmb / scpk_trackStepEmb の全引数 (指定機体の収束済み
%   計画解 results/landing_*.mat を初期推定にした実データ) と, 構造体を埋める
%   fill_cfg / fill_pp / fill_qp / fill_tp 関数. examples/ の各 main から使う.
%   cfg は計画ファイルに保存されたもの (GUIで諸元を変えた場合も追随).
%
%   生成コード (gnc/) 自体は機体非依存で, ここで変わるのは例データのみ.
%
%   See also CODEGENPLANITER, SCPCODEGENZIP, VERIFYEMBEDDED
if nargin < 1 || isempty(vehicle), vehicle = 'starship'; end
here = fileparts(mfilename('fullpath'));  proj = fileparts(here);
addpath(fullfile(proj,'src'));
if strcmpi(vehicle,'falcon9'), planFile = 'landing_falcon9.mat';
else,                          planFile = 'landing_vert.mat'; end
S = load(fullfile(proj,'results',planFile));
cfg = S.cfg;                      % 計画時の機体定数 (諸元オーバーライド込み)
sol=S.sol; opt=S.opt; x0=S.x0; sc=cfg.sc;
sx=[repmat(sc.L,3,1);repmat(sc.V,3,1);ones(4,1);repmat(1/sc.T,3,1);cfg.m0];
xT=[cfg.hmin;0;0;0;0;0;0;0;0;0;0;0];
dtv=arrayfun(@(j) 1/sum(opt.phase==j), opt.phase);
sh=opt.trShrinkRate^(opt.maxIter-1);
trX=max(opt.trXmin,opt.trX*sh); trU=max(opt.trUmin,opt.trU*sh); trSig=max(opt.trSigMin,opt.trSig*sh);
o2=opt; o2.trX=trX; o2.trU=trU; o2.trSig=trSig;
[pp,qp]=scpk.planParams(o2, trX, trU, trSig);

outdir = fullfile(proj,'src','cpp','codegen_planiter_lib','examples_data');
if ~exist(outdir,'dir'), mkdir(outdir); end
fid = fopen(fullfile(outdir,'plan_example_data.h'),'w');
c = onCleanup(@() fclose(fid));
fprintf(fid,'/* plan_example_data.h — GNC呼び出し例の実データ (自動生成).\n');
fprintf(fid,' * 生成: exportPlanExample.m / 元データ: %s (%s 着陸解) */\n', planFile, vehicle);
fprintf(fid,'#ifndef PLAN_EXAMPLE_DATA_H\n#define PLAN_EXAMPLE_DATA_H\n');
fprintf(fid,'#include <math.h>\n#include "gncCore_lib_types.h"\n\n');

emitArr(fid,'ex_x0nd', x0./sx);
emitArr(fid,'ex_xT',   xT);
emitArr(fid,'ex_xl',   sol.xhat);
emitArr(fid,'ex_ul',   sol.uhat);
emitArr(fid,'ex_gl',   sol.ghat);
emitArr(fid,'ex_sigl', sol.sigma/sc.T);
emitArr(fid,'ex_phase',double(opt.phase));
emitArr(fid,'ex_eng',  double(opt.engSched));
emitArr(fid,'ex_dtv',  dtv);
emitArr(fid,'ex_tiltN',opt.tiltMaxNode);

%% --- 追従MPC / GNC統合例用: 高密度参照とスケール ---
topt = scpk.track6Options();
refD = scpk.densify6(sol, cfg, min(0.1, topt.dt/2));
tp   = scpk.trackParams(topt, cfg);
nR = numel(refD.t);  nU = size(refD.uhat,2);
emitArr(fid,'ex_ref_t',   refD.t(:).');            % 参照時刻 [s]
emitArr(fid,'ex_ref_x',   refD.xhat);              % 参照状態 (無次元 14 x nR)
emitArr(fid,'ex_ref_u',   refD.uhat);              % 参照制御 (無次元 7 x nU)
emitArr(fid,'ex_ref_eng', double(refD.engSched(:)).');
fprintf(fid,'static const int    ex_H     = %d;    /* 追従ホライズン節点 */\n', topt.H);
fprintf(fid,'static const double ex_dtMpc = %s;  /* 予測ノード間隔 [s] (参照窓の刻み) */\n', lit(topt.dt));
fprintf(fid,'static const double ex_dtCtrl = %s;  /* 追従MPCの実行周期 [s] (track6Options.dtCtrl) */\n', lit(topt.dtCtrl));
fprintf(fid,'static const double ex_dtPlant = %s;  /* プラント積分刻み [s] (track6Options.dtPlant) */\n', lit(topt.dtPlant));
fprintf(fid,'static const double ex_scL = %s, ex_scV = %s, ex_scT = %s;\n', ...
    lit(sc.L), lit(sc.V), lit(sc.T));
fprintf(fid,'static const double ex_m0 = %s, ex_Fs = %s;\n', lit(cfg.m0), lit(cfg.Fs));
fprintf(fid,'static const double ex_tdAlt = %s;  /* 接地判定高度 [m] */\n\n', lit(cfg.hmin*sc.L));

emitFill(fid,'fill_cfg','struct0_T',cfg);
emitFill(fid,'fill_pp', 'struct3_T',pp);
emitFill(fid,'fill_qp', 'struct4_T',qp);
emitFill(fid,'fill_tp', 'struct5_T',tp);
fprintf(fid,'#endif /* PLAN_EXAMPLE_DATA_H */\n');
fprintf('生成: %s\n', fullfile(outdir,'plan_example_data.h'));

%% 等価性検証 (verifyEmbedded) 用: 同一入力を .mat でも保存
args = struct('x0nd',x0./sx, 'xT',xT, 'xl',sol.xhat, 'ul',sol.uhat, ...
    'gl',sol.ghat, 'sigl',sol.sigma/sc.T, 'phase',double(opt.phase), ...
    'eng',double(opt.engSched), 'dtv',dtv, 'tiltN',opt.tiltMaxNode, ...
    'cfg',cfg, 'pp',pp, 'qp',qp, 'tp',tp, 'H',topt.H, 'dtMpc',topt.dt, ...
    'dtCtrl',topt.dtCtrl, 'dtPlant',topt.dtPlant, 'refD',refD, ...
    'vehicle',vehicle);   %#ok<NASGU>
save(fullfile(proj,'results','plan_example_args.mat'),'-struct','args');
end

function emitArr(fid,name,A)
fprintf(fid,'static const int %s_size[2] = {%d, %d};\n', name, size(A,1), size(A,2));
fprintf(fid,'static const double %s[%d] = {\n', name, max(1,numel(A)));
v = A(:);  % 列優先 (Coder と同じ)
if isempty(v), fprintf(fid,'  0.0\n};\n\n'); return; end
for i=1:numel(v)
    fprintf(fid,'  %s%s', lit(v(i)), sep(i,numel(v)));
end
fprintf(fid,'};\n\n');
end

function emitFill(fid,fname,tname,s)
fprintf(fid,'static void %s(%s *s)\n{\n', fname, tname);
emitStruct(fid,'s->',s);
fprintf(fid,'}\n\n');
end

function emitStruct(fid,prefix,s)
fn = fieldnames(s);
for k=1:numel(fn)
    v = s.(fn{k});
    if isstruct(v)
        emitStruct(fid,[prefix fn{k} '.'],v);
    elseif ischar(v) || isstring(v)
        cs = char(v);
        for i=1:numel(cs)
            fprintf(fid,'  %s%s[%d] = %d;\n', prefix, fn{k}, i-1, double(cs(i)));
        end
    elseif isscalar(v)
        fprintf(fid,'  %s%s = %s;\n', prefix, fn{k}, lit(double(v)));
    else
        vv = v(:);  % 列優先
        for i=1:numel(vv)
            fprintf(fid,'  %s%s[%d] = %s;\n', prefix, fn{k}, i-1, lit(double(vv(i))));
        end
    end
end
end

function t = lit(x)
if isnan(x),      t = 'NAN';
elseif isinf(x),  t = ternary(x>0,'INFINITY','-INFINITY');
else,             t = sprintf('%.17g', x);
end
end

function t = ternary(c,a,b), if c, t=a; else, t=b; end, end

function t = sep(i,n)
if i==n, t = sprintf('\n');
elseif mod(i,6)==0, t = sprintf(',\n');
else, t = ', ';
end
end
