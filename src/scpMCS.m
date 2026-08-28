function out = scpMCS(prob, dispFile, N, prm)
%SCPMCS  問題定義 PROB に対するモンテカルロ解析 (閉ループ一括実行 + 統計).
%
%   OUT = SCPMCS(PROB, DISPFILE, N)
%   OUT = SCPMCS(PROB, DISPFILE, N, PRM)
%
%   PROB の閉ループ設定 (追従重み, refSync, 速度FB, 着陸コミットなど) を
%   引き継いだうえで, DISPFILE の変動定義に従い N ラン実行する.
%
%   入力:
%     PROB      scpProblem の出力 (計画済みであること: 先に scpPlan を実行)
%     DISPFILE  変動定義. 次のどちらか:
%                 - .m 関数名 (例 'dispersions_starship'): spec を返す関数
%                 - .json パス (例 'config/dispersions_falcon9.json')
%               書式は {名前, 分布, p1, p2} の配列. 分布は 'uniform' (p1=下限,
%               p2=上限) か 'normal' (p1=平均, p2=標準偏差).
%               使える名前: thrEff, windY, navJump, dr0x/dr0y/dr0z [m],
%               dvBx/dvBy/dvBz [m/s], ほか runClosedLoopReplan の任意の数値 prm
%     N         ラン数
%     PRM       追加設定 (省略可):
%                 .parallel    true で parfor 並列 (既定 false)
%                 .seed        乱数シード (既定 1)
%                 .noPlot      1 で図を出さない
%                 .progressFcn @(done,N) 進捗コールバック
%
%   出力 OUT: .res(i) 各ランの終端指標 (horiz, vTd, tilt, tEnd, fuel, ok, traj),
%             .N, .spec. 図: 鳥瞰軌道 + 着陸精度散布 + 統計.
%
%   例:
%     prob = scpProblem('falcon9');  scpPlan(prob);
%     out = scpMCS(prob, 'config/dispersions_falcon9.json', 20, ...
%                  struct('parallel',true));
%
%   See also SCPPROBLEM, SCPPLAN, SCPCLOSEDLOOP, RUNMCS_SCP, LOADDISPERSIONS
src = fileparts(mfilename('fullpath'));  proj = fileparts(src);
addpath(src, fullfile(src,'cpp'), fullfile(proj,'util'), fullfile(proj,'config'));
if nargin < 4, prm = struct(); end
seed = 1;
if isfield(prm,'seed'), seed = prm.seed; prm = rmfield(prm,'seed'); end

%% prob の閉ループ設定を引き継ぐ (scpClosedLoop と同じ写像)
prm.planFile = prob.planFile;
prm.trackOpt = prob.track;
if isfield(prob,'refSync') && ~isfield(prm,'refSync'), prm.refSync = prob.refSync; end
if isfield(prob,'velFB') && ~isfield(prm,'velFB'), prm.velFB = prob.velFB; end
if isfield(prob,'velFBi') && ~isfield(prm,'velFBi'), prm.velFBi = prob.velFBi; end
if isfield(prob,'latFreezeAlt') && ~isfield(prm,'latFreezeAlt'), prm.latFreezeAlt = prob.latFreezeAlt; end
if isfield(prob,'ctlModeForce') && ~isempty(prob.ctlModeForce) && ~isfield(prm,'ctlMode'), prm.ctlMode = prob.ctlModeForce; end
if isfield(prob,'okCrit') && ~isfield(prm,'okCrit'), prm.okCrit = prob.okCrit; end
if isfield(prob,'errTrig') && ~isfield(prm,'errTrig'), prm.errTrig = prob.errTrig; end
if isfield(prob,'windProf') && ~isfield(prm,'windProf'), prm.windProf = prob.windProf; end
if isfield(prob,'cutoffAlt') && ~isfield(prm,'cutoffAlt'), prm.cutoffAlt = prob.cutoffAlt; end

out = runMCS_scp(dispFile, N, seed, prm);
end
