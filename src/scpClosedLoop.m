function R = scpClosedLoop(prob, prm)
%SCPCLOSEDLOOP  問題定義 PROB の計画に対する閉ループ解析 (追従MPC+再計画).
%
%   R = SCPCLOSEDLOOP(PROB, PRM)
%   PRM: runClosedLoopReplan の外乱/設定 (thrEff, windY, navJump, errTrig,
%        dr0, dvB0, ...). prob.track の重み/スケールが追従MPCに渡る.
%
%   See also SCPPROBLEM, SCPPLAN, RUNCLOSEDLOOPREPLAN
src = fileparts(mfilename('fullpath'));  proj = fileparts(src);
addpath(src, fullfile(src,'cpp'), fullfile(proj,'util'));
if nargin < 2, prm = struct(); end
prm.planFile = prob.planFile;
prm.trackOpt = prob.track;
if isfield(prob,'refSync') && ~isfield(prm,'refSync'), prm.refSync = prob.refSync; end
if isfield(prob,'velFB') && ~isfield(prm,'velFB'), prm.velFB = prob.velFB; end
if isfield(prob,'velFBi') && ~isfield(prm,'velFBi'), prm.velFBi = prob.velFBi; end
if isfield(prob,'latFreezeAlt') && ~isfield(prm,'latFreezeAlt'), prm.latFreezeAlt = prob.latFreezeAlt; end
if isfield(prob,'errTrig') && ~isfield(prm,'errTrig'), prm.errTrig = prob.errTrig; end
if isfield(prob,'windProf') && ~isfield(prm,'windProf'), prm.windProf = prob.windProf; end
if isfield(prob,'cutoffAlt') && ~isfield(prm,'cutoffAlt'), prm.cutoffAlt = prob.cutoffAlt; end
%% 機体既定の制御方式 (prm.ctlMode の明示指定が優先)
if isfield(prob,'ctlModeForce') && ~isempty(prob.ctlModeForce) && ~isfield(prm,'ctlMode')
    prm.ctlMode = prob.ctlModeForce;
end
R = runClosedLoopReplan(prm);
end
