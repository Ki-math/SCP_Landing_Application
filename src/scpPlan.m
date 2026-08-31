function [sol,cfg] = scpPlan(prob, quick, progFcn)
%SCPPLAN  問題定義 PROB から着陸計画を解く (チューニング連鎖を汎用実行).
%
%   [SOL,CFG] = SCPPLAN(PROB)        コールド + prob.passes の連鎖で解いて保存
%   [SOL,CFG] = SCPPLAN(PROB, true)  保存済み planFile があれば読むだけ
%   [SOL,CFG] = SCPPLAN(PROB, false, PROGFCN)  進捗コールバック PROGFCN(0..1,msg)
%
%   See also SCPPROBLEM, SCPCLOSEDLOOP
src = fileparts(mfilename('fullpath'));  proj = fileparts(src);
addpath(src, fullfile(src,'cpp'), fullfile(proj,'util'));
resf = fullfile(proj,'results',prob.planFile);
scpCheckMex();                     % モデル構造体の変更を検出したらMEXを自動再生成
cfg = prob.cfg;
%% 風況プロファイルを計画・追従モデルへ反映 (8点テーブルに再標本化).
%% 既知の風はフィードフォワードで織り込み, MCSの windScale 変動など残差は
%% 閉ループのフィードバックが吸収する.
if isfield(prob,'windProf') && ~isempty(prob.windProf)
    %% 風況向けの機体制約緩和 (scpWindTune) を自動適用する. 既定の姿勢制約は
    %% 無風テンプレート用に締めてあり, そのままだと風トリムも divert もできず
    %% 計画残差が 10m 級で残る (実測: 50m オフセット時 40.8m -> 適用で 1.9m)
    if ~(isfield(prob.opt,'autoWindTune') && ~prob.opt.autoWindTune)
        wasTuned = isfield(prob,'windTuned') && prob.windTuned;
        prob = scpWindTune(prob);
        if ~wasTuned
            fprintf('風況向け自動チューニング適用 (scpWindTune. prob.opt.autoWindTune=false で無効化)\n');
        end
    end
    wpz = prob.windProf;
    h8 = linspace(wpz.h(1), wpz.h(end), 8);
    for c = {'cfg','cfgPlan'}
        prob.(c{1}).wOn = 1;
        prob.(c{1}).wTabH = h8;
        prob.(c{1}).wTabY = interp1(wpz.h, wpz.wy, h8);
        prob.(c{1}).wTabZ = interp1(wpz.h, wpz.wz, h8);
    end
    cfg = prob.cfg;
    %% 横方向の箱制約 (crMax/drBox) を風ドリフト推定ぶん自動拡張する.
    %% 元の箱のままだと自由ドリフトが箱に当たり求解が数値破綻する (実測).
    drift = 1.2*sum(prob.sig0);                  % 飛行時間の概算 [s] x 1.2
    dCR = max(abs(wpz.wy))*drift + 20;
    dDR = max(abs(wpz.wz))*drift + 20;
    if isfield(prob.opt,'crMax') && ~isempty(prob.opt.crMax) && isfinite(prob.opt.crMax)
        prob.opt.crMax = max(prob.opt.crMax, dCR);
    end
    if isfield(prob.opt,'drBox') && ~isempty(prob.opt.drBox)
        prob.opt.drBox = [prob.opt.drBox(1)-dDR, prob.opt.drBox(2)+dDR];
    end
    for p = 1:numel(prob.passes)                 % passesの箱上書きにも同じ拡張
        if isfield(prob.passes(p).set,'crMax')
            prob.passes(p).set.crMax = max(prob.passes(p).set.crMax, dCR);
        end
        if isfield(prob.passes(p).set,'drBox')
            prob.passes(p).set.drBox = [prob.passes(p).set.drBox(1)-dDR, prob.passes(p).set.drBox(2)+dDR];
        end
    end
    fprintf('計画に風況プロファイルを反映 (%d点 -> 8点テーブル, 横箱を+%.0f/+%.0fm拡張)\n', ...
        numel(wpz.h), dCR, dDR);
end
if nargin < 3, progFcn = []; end
pg = @(f,m) progressCall(progFcn, f, m);
if nargin >= 2 && quick && exist(resf,'file')
    S = load(resf);  sol = S.sol;
    fprintf('保存済み計画: %s (tf=%.1fs 燃料%.2ft)\n', prob.planFile, sol.tf, sol.propellant/1e3);
    return
end

%% 初期条件の変更にフェーズ時間チューニングを追随させる (相似伸縮).
%% sig0 / sigMin / sigMax / 継続法のσ注入はテンプレートの初期条件用に調整して
%% あるため, 高度や速度を変えると実現可能な時間割りが箱の外に出て
%% 収束しない (nu が残る) ことがある. 特徴時間 h0/|v0| の比で伸縮して防ぐ.
if isfield(prob,'x0Ref') && ~isempty(prob.x0Ref)
    tRef = prob.x0Ref(1)/max(norm(prob.x0Ref(4:6)), 1);
    tNow = prob.x0(1)/max(norm(prob.x0(4:6)), 1);
    tau = min(max(tNow/tRef, 0.4), 2.5);
    if abs(tau - 1) > 0.02
        prob.sig0 = prob.sig0*tau;
        prob.opt.sigMin = prob.opt.sigMin*tau;
        prob.opt.sigMax = prob.opt.sigMax*tau;
        for p = 1:numel(prob.passes)
            if isfield(prob.passes(p).set,'sigMin')
                prob.passes(p).set.sigMin = prob.passes(p).set.sigMin*tau;
            end
            if isfield(prob.passes(p).set,'sigMax')
                prob.passes(p).set.sigMax = prob.passes(p).set.sigMax*tau;
            end
            if ~isempty(prob.passes(p).sigma)
                prob.passes(p).sigma = prob.passes(p).sigma*tau;
            end
        end
        fprintf('初期条件に合わせフェーズ時間チューニングを %.2f 倍に伸縮\n', tau);
    end
end

opt = prob.opt;
opt.phase = prob.phase;  opt.engSched = prob.eng;  opt.tiltMaxNode = prob.tiltN;
nP = numel(prob.passes);
fprintf('=== %s pass0: cold ===\n', prob.vehicle);
pg(0.02, 'コールドスタート求解中...');
opt.verbose = true;
[sol,~] = scpk.plan6ft(prob.x0, prob.xT, prob.sig0, prob.cfgPlan, opt);
opt.verbose = false;
for p = 1:nP
    fprintf('=== pass%d ===\n', p);
    pg(0.45 + 0.5*(p-1)/nP, sprintf('調整パス %d/%d ...', p, nP));
    fn = fieldnames(prob.passes(p).set);
    for i = 1:numel(fn), opt.(fn{i}) = prob.passes(p).set.(fn{i}); end
    if ~isempty(prob.passes(p).sigma), sol.sigma = prob.passes(p).sigma; end
    [sol,~] = scpk.plan6ft(prob.x0, prob.xT, sol.sigma, prob.cfgPlan, opt, sol);
end
pg(1, '完了');

%% 解の妥当性チェック: 数値破綻した解を保存すると閉ループが不可解に落ちるため,
%% ここで明確にエラーにする (原因と対処をメッセージで案内)
if ~isfinite(sol.tf) || sol.tf <= 0.5 || any(~isfinite(sol.r(:)))
    error(['計画が数値破綻しました (tf=%.2f)。強風の場合は横制約や姿勢レートを緩めて' ...
           'ください (例: prob.opt.crMax拡大, prob.opt.wMaxFlip/wMaxTight緩和, ' ...
           'prob.tiltN緩和。USER_GUIDE §6「大気モデルと風」参照)'], sol.tf);
end

if sol.virtCtrl > 1e-3
    warning('scpk:planNotConverged', ...
        ['計画が完全収束していません (仮想制御 nu=%.1e > 1e-3)。結果は物理的に' ...
         '無効な可能性があります。sig0/sigMin/sigMax (フェーズ時間の箱) や重みの' ...
         '調整、初期条件の見直しを検討してください'], sol.virtCtrl);
end

rE = sol.r(:,end);  rd = quat2dcm(sol.q(:,end).').'*sol.v(:,end);
fprintf('終端: 高度%.1fm(目標%.0f) 水平%.1fm |v|%.2f 傾斜%.1fdeg 燃料%.2ft tf=%.1fs nu=%.1e\n', ...
    rE(1), cfg.hmin*cfg.sc.L, hypot(rE(2),rE(3)), norm(rd), ...
    acosd(max(-1,1-2*(sol.q(3,end)^2+sol.q(4,end)^2))), sol.propellant/1e3, sol.tf, sol.virtCtrl);
x0 = prob.x0;
%% 保存する opt の QP 設定はベース値に戻す. 磨きパスの厳格QP (1e-6/40000) は
%% オフライン計画専用で, 保存 opt はオンライン再計画 (replan6) や組み込み例の
%% 生成 (exportPlanExample) に使われるため, 漏れるとリアルタイム性を壊す
opt.qp = prob.opt.qp;
save(resf, 'sol','cfg','x0','opt');
fprintf('保存: %s\n', resf);
end

function progressCall(f, frac, msg)
if ~isempty(f)
    try, f(frac, msg); catch, end
end
end
