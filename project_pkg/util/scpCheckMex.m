function ok = scpCheckMex(autoBuild)
%SCPCHECKMEX  生成MEXとモデル構造体の整合を検査し, 不整合なら自動再生成.
%
%   OK = SCPCHECKMEX()       検査し, 不整合なら再生成 (要MATLAB Coder, 数分)
%   OK = SCPCHECKMEX(false)  検査のみ (不整合なら警告して OK=false)
%
%   生成MEX (linDisc6All_mex, planIterEmb_mex) は cfg / pp 構造体の
%   フィールド構成に厳密一致が必要. モデル (model6 / modelFalcon9 /
%   planOptions6 / planParams) にフィールドを追加・削除すると不整合になる.
%   本関数は前回生成時に保存した指紋 (results/mex_fingerprint.mat) と現在の
%   構造体レイアウトを比較して検出する. scpPlan から毎回自動で呼ばれる.
%
%   See also MEXFINGERPRINT, CODEGENBUILD, CODEGENPLANITER, SCPPLAN
if nargin < 1, autoBuild = true; end
ok = true;
here = fileparts(mfilename('fullpath'));  proj = fileparts(here);
if exist('linDisc6All_mex','file') ~= 3
    return;                                % MEXなし: MATLAB実装で動くので整合問題なし
end
fpFile = fullfile(proj,'results','mex_fingerprint.mat');
fpNow = mexFingerprint();
if exist(fpFile,'file')
    S = load(fpFile);
    if strcmp(S.fp, fpNow), return; end    % 一致: 何もしない
else
    %% 指紋ファイルが無い (旧環境): 現MEXが動くか実呼び出しで確認し, 指紋を初期化
    try
        cfg = scpk.model6();
        xl = repmat([1;0;0; -0.1;0;0; 1;0;0;0; 0;0;0; 1], 1, 2);
        linDisc6All_mex(xl, [0.5;0;0;0;0;0;0], 1.0, 1, 1.0, cfg);
        fp = fpNow;  save(fpFile, 'fp');   %#ok<NASGU>
        return;
    catch
        %% 実呼び出しで失敗 -> 再生成が必要
    end
end
ok = false;
if ~autoBuild
    warning('scpk:mexStale', ...
        ['モデル構造体の変更を検出しました。生成MEXが古いため ' ...
         'codegenBuild / codegenPlanIter の再実行が必要です']);
    return;
end
fprintf(['モデル構造体の変更を検出 -> 生成MEXを再ビルドします ' ...
         '(codegenBuild + codegenPlanIter, 数分かかります)\n']);
cwd = pwd;
try
    addpath(here);
    codegenBuild();
    codegenPlanIter();
    fp = fpNow;  save(fpFile, 'fp');       %#ok<NASGU>
    ok = true;
    fprintf('再ビルド完了 (指紋を更新)\n');
catch ME
    cd(cwd);
    error('scpk:mexRebuildFailed', ...
        'MEX再生成に失敗しました (%s)。手動で codegenBuild / codegenPlanIter を実行してください', ...
        ME.message);
end
cd(cwd);
end
