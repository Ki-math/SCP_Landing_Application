%% run_main — 再利用ロケット着陸解析 ワークフロー (Tool API)
% 問題定義(scpProblem) -> 編集 -> 計画(scpPlan) -> 閉ループ(scpClosedLoop)
% -> plot/anim -> MCS(runMCS_scp) -> 組み込みzip(scpCodegenZip)
%
% ■ モデルのプラグイン方式
%   予測モデルの実体 = scpk.dynamics6(x,u,cfg). 機体差は cfg:
%     scpk.model6()       Starship  (surfMode=1: ベリーフラップ)
%     scpk.modelFalcon9() Falcon9級 (surfMode=2: グリッドフィン)
%   任意の力学は [f,A,B]=dyn(x,u,cfg) の同一シグネチャで差し替え
%   (CasADi生成の解析ヤコビアン関数を接続する場合もこの形式).
%   ※ cfg のフィールド構成を変えたら util/codegenBuild を再実行
%     (生成MEXは構造体順序に厳密).
%
% ■ 重み/スケーリング/制約は prob.opt (計画) と prob.track (追従) を編集
% ■ 詳細: docs/SCP_formulation.md
clear; clc;
here = fileparts(mfilename('fullpath'));
run(fullfile(fileparts(here),'setup.m'));

%% ============ 1. 解析設定 ============
P.vehicle   = 'falcon9';    % 'starship' | 'falcon9'
P.planMode  = 'regen';        % 'load' 保存済み | 'regen' 再生成
P.runCL     = true;          % 閉ループ解析
P.runMCS    = false;         % モンテカルロ
P.mcsFile   = 'dispersions_starship';
P.mcsN      = 8;
P.mcsPar    = false;         % MCS並列 (parfor)
P.makeZip   = false;         % 組み込みzipの生成 (モデル変更後は true 推奨)
P.anim      = true;
P.animSpeed = 4;

% 閉ループ外乱
D.thrEff  = 0.97;   D.windY = 0.3;   D.navJump = 0;
D.replan  = true;   D.errTrig = 40;

%% ============ 2. 問題定義 (ここを編集して調整評価する) ============
prob = scpProblem(P.vehicle);
% --- 編集例 (コメントを外して使う) ---
% prob.opt.tol.pos  = 2;             % スケーリング (許容誤差)
% prob.opt.lamTerm  = 1e8;           % 終端重み
% prob.opt.wFuel    = 25;            % 燃料重み
% prob.opt.drBox    = [-400 20];     % 行き過ぎ制約
% prob.opt.sigMax(4)= 45;            % フェーズ時間上限
% prob.track.wPos   = 16;            % 追従MPCの位置重み
% prob.track.H      = 30;            % 追従ホライズン節点数

%% ============ 3. 計画 ============
[sol,cfg] = scpPlan(prob, strcmp(P.planMode,'load'));

%% ============ 4. 閉ループ解析 ============
if P.runCL
    prm = struct('thrEff',D.thrEff, 'windY',D.windY, 'navJump',D.navJump);
    if D.replan, prm.errTrig = D.errTrig; else, prm.errTrig = inf; end
    R = scpClosedLoop(prob, prm);
    cl = R.log;

    figure('Color','w','Position',[60 60 1200 700],'Name','着陸解析: 計画 vs 閉ループ');
    tiledlayout(2,3,'Padding','compact','TileSpacing','compact');
    tiltOf = @(X) arrayfun(@(k) acosd(max(-1,min(1,1-2*(X(9,k)^2+X(10,k)^2)))), 1:size(X,2));
    nexttile; plot(sol.t, sol.r(1,:), 'k--', cl.t, cl.x(1,:), 'b','LineWidth',1.4);
    grid on; xlabel('t [s]'); ylabel('高度 [m]'); legend('計画','閉ループ');
    nexttile; plot(sol.t, sol.r(3,:), 'k--', cl.t, cl.x(3,:), 'b','LineWidth',1.4);
    grid on; xlabel('t [s]'); ylabel('ダウンレンジ [m]');
    nexttile; plot(sol.t, tiltOf([zeros(6,numel(sol.t));sol.q;zeros(4,numel(sol.t))]), 'k--', ...
                   cl.t, tiltOf(cl.x), 'b','LineWidth',1.4);
    grid on; xlabel('t [s]'); ylabel('傾斜角 [deg]');
    nexttile; plot(sol.t, vecnorm(sol.v), 'k--', cl.t, vecnorm(cl.x(4:6,:)), 'b','LineWidth',1.4);
    grid on; xlabel('t [s]'); ylabel('速度 [m/s]');
    nexttile; plot(sol.t(1:end-1), sol.Tmag(1:numel(sol.t)-1)/1e6, 'k--', ...
                   cl.t, vecnorm(cl.u(1:3,:))*cfg.Fs/1e6, 'b','LineWidth',1.4);
    grid on; xlabel('t [s]'); ylabel('推力 [MN]');
    nexttile; histogram(cl.qpT*1e3, 30); grid on; xlabel('追従QP時間 [ms]');
    title(sprintf('MPC %d回 平均%.0fms 収束%.0f%%', numel(cl.qpT), ...
          mean(cl.qpT)*1e3, 100*mean(strcmp(cl.st,'converged'))));

    if P.anim
        aopt = struct('speed',P.animSpeed,'fps',20);
        fa = figure('Color','w','Name','飛行アニメーション');
        axA = axes(fa);
        if strcmp(P.vehicle,'falcon9')
            aopt.style = 'falcon9';  aopt.speed = 1.5;
        end
        animateVehicleAx(axA, cl.t, cl.x, cl.u, cfg, aopt);
    end
end

%% ============ 5. モンテカルロ解析 ============
if P.runMCS
    mprm = struct('parallel',P.mcsPar, 'planFile',prob.planFile);
    mcs = runMCS_scp(P.mcsFile, P.mcsN, 1, mprm);
end

%% ============ 6. 組み込み用 C パッケージ (zip) ============
if P.makeZip
    zipf = scpCodegenZip(true);    % モデル/cfg変更後は true で再生成
    fprintf('組み込みパッケージ: %s\n', zipf);
end
