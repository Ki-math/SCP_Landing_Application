function setup()
%SETUP  プロジェクトのパス設定 (セッション開始時に1回実行).
%
%   >> setup
%
%   フォルダ構成:
%     src/       ライブラリ本体 (+scpk パッケージ, API, C++ソース/MEX)
%     util/      実行ドライバ・可視化・コード生成 (legacy/ は旧世代)
%     examples/  コマンド実行ワークフロー (example_starship / example_falcon9)
%     config/    設定JSON・変動定義
%     results/   計画解・実行結果 (mat)
%
%   See also EXAMPLE_STARSHIP, EXAMPLE_FALCON9, SCPAPP
proj = fileparts(mfilename('fullpath'));
addpath(fullfile(proj,'src'), fullfile(proj,'src','cpp'), ...
        fullfile(proj,'util'), fullfile(proj,'util','legacy'), ...
        fullfile(proj,'examples'), fullfile(proj,'config'));
end
