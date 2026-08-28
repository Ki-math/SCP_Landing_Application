function zipf = scpCodegenZip(regen)
%SCPCODEGENZIP  組み込み用の純C/C++ソースパッケージを生成し zip にまとめる.
%
%   ZIPF = SCPCODEGENZIP()      既存の生成物からパッケージ (生成物が無ければ生成)
%   ZIPF = SCPCODEGENZIP(true)  コード生成からやり直してパッケージ (数分)
%
%   パッケージ内容 (MATLAB/MEX 依存ゼロ. コンパイラだけでビルド可能):
%     gnc/      GNCコアのフルC (MATLAB Coder生成, BLASフリー).
%               2つの独立エントリポイント:
%                 scpk_planIterEmb  計画SCP 1反復 (フル計画/オンライン再計画)
%                 scpk_trackStepEmb 追従MPC 1周期 (LTV追従QP)
%               力学 dyn() も公開 (プラントシミュレーションに使用可)
%     guidance/ 誘導ロジック部品 (手書き純C): 参照サンプリング,
%               点火ディスパッチ (高度→参照時刻), 鉛直速度FB
%     solver/   手書き C++ PIPG QPソルバ単体 (pipg_core.hpp, ヘッダオンリー)
%     examples/ 実データ入りサンプル main:
%               計画単体 / 追従MPC単体 / ソルバ単体 / GNC統合閉ループ
%     README.md 構成・エントリポイント仕様・ビルド/実行手順
%
%   出力: <プロジェクト>/scp_landing_embedded.zip
%   検証: パッケージ内に mex.h / tmwtypes.h / BLAS 参照が無いことを確認する.
%
%   See also CODEGENPLANITER, EXPORTPLANEXAMPLE, SCPPROBLEM
src = fileparts(mfilename('fullpath'));  proj = fileparts(src);
addpath(src, fullfile(src,'cpp'), fullfile(proj,'util'));
if nargin < 1, regen = false; end

libdir = fullfile(src,'cpp','codegen_planiter_lib');
if regen || ~exist(fullfile(libdir,'scpk_planIterEmb.h'),'file') || ...
            ~exist(fullfile(libdir,'scpk_trackStepEmb.h'),'file')
    fprintf('コード生成を実行 (数分)...\n');
    codegenPlanIter();
end
exdata = fullfile(libdir,'examples_data','plan_example_data.h');
if regen || ~exist(exdata,'file')
    exportPlanExample();
end

%% --- ステージング ---
stg = fullfile(proj,'embedded_pkg');
if exist(stg,'dir'), rmdir(stg,'s'); end
mkdir(fullfile(stg,'gnc'));  mkdir(fullfile(stg,'guidance'));
mkdir(fullfile(stg,'solver'));  mkdir(fullfile(stg,'examples'));
cf = [dir(fullfile(libdir,'*.c')); dir(fullfile(libdir,'*.h'))];
for i = 1:numel(cf)
    copyfile(fullfile(cf(i).folder,cf(i).name), fullfile(stg,'gnc',cf(i).name));
end
cpp = fullfile(src,'cpp');
gf = [dir(fullfile(cpp,'guidance','*.c')); dir(fullfile(cpp,'guidance','*.h'))];
for i = 1:numel(gf)
    copyfile(fullfile(gf(i).folder,gf(i).name), fullfile(stg,'guidance',gf(i).name));
end
copyfile(fullfile(cpp,'pipg_core.hpp'),          fullfile(stg,'solver','pipg_core.hpp'));
copyfile(fullfile(cpp,'main_planner_example.c'), fullfile(stg,'examples','main_planner_example.c'));
copyfile(fullfile(cpp,'main_tracker_example.c'), fullfile(stg,'examples','main_tracker_example.c'));
copyfile(fullfile(cpp,'main_gnc_example.c'),     fullfile(stg,'examples','main_gnc_example.c'));
copyfile(fullfile(cpp,'main_solver_example.cpp'),fullfile(stg,'examples','main_solver_example.cpp'));
copyfile(exdata,                                 fullfile(stg,'examples','plan_example_data.h'));

%% --- README ---
tmpl = fullfile(proj,'docs','embedded_README.md');
if ~exist(tmpl,'file'), error('docs/embedded_README.md がありません'); end
copyfile(tmpl, fullfile(stg,'README.md'));

%% --- 純度検証: MATLAB/MEX/BLAS 依存ゼロ ---
all = dir(fullfile(stg,'**','*'));
bad = {};
for i = 1:numel(all)
    if all(i).isdir, continue; end
    [~,~,e] = fileparts(all(i).name);
    if ~ismember(lower(e), {'.c','.h','.hpp','.cpp'}), continue; end
    txt = fileread(fullfile(all(i).folder,all(i).name));
    if ~isempty(regexpi(txt,'mex\.h|tmwtypes\.h|mexFunction|dgemm|dgemv|cblas','once'))
        bad{end+1} = all(i).name; %#ok<AGROW>
    end
end
if ~isempty(bad)
    error('純ソース検証NG: MATLAB/BLAS依存が残存: %s', strjoin(bad,', '));
end
fprintf('純度検証 OK: mex.h / tmwtypes.h / BLAS 参照 0件\n');

%% --- zip ---
zipf = fullfile(proj,'scp_landing_embedded.zip');
if exist(zipf,'file'), delete(zipf); end
zip(zipf, {'gnc','guidance','solver','examples','README.md'}, stg);
d = dir(zipf);
fprintf('パッケージ作成: %s (%.0f KB, gnc %d + guidance %d ファイル)\n', ...
    zipf, d.bytes/1024, numel(cf), numel(gf));
end
