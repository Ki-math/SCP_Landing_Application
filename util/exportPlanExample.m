function exportPlanExample()
%EXPORTPLANEXAMPLE  計画1反復デモ用の実データCヘッダを生成する.
%
%   codegen_planiter_lib/examples_data/plan_example_data.h を出力.
%   内容: エントリポイント scpk_planIterEmb の全引数 (Starship着陸問題の
%   収束済み解を初期推定にした実データ) と, cfg/pp/qp 構造体を埋める
%   fill_cfg / fill_pp / fill_qp 関数. main_planner_example.c から使う.
%
%   See also CODEGENPLANITER, SCPCODEGENZIP
here = fileparts(mfilename('fullpath'));  proj = fileparts(here);
addpath(fullfile(proj,'src'));
cfg = scpk.model6();
S = load(fullfile(proj,'results','landing_vert.mat'));
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
fprintf(fid,'/* plan_example_data.h — scpk_planIterEmb 呼び出し例の実データ (自動生成).\n');
fprintf(fid,' * 生成: exportPlanExample.m / 元データ: landing_vert.mat (Starship着陸解) */\n');
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
fprintf(fid,'static const double ex_dtCtrl = 0.1;  /* 追従MPCの実行周期 [s] */\n');
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
    'dtCtrl',0.1, 'refD',refD);   %#ok<NASGU>
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
