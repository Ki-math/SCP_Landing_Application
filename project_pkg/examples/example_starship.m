%EXAMPLE_STARSHIP  Starship型機体の着陸 通しワークフロー (ベリーフロップ->フリップ).
%
%   >> setup            (初回のみ. パス設定)
%   >> example_starship
%
%   流れ: 1.問題設定 -> 2.軌道計画 -> 3.閉ループ -> 4.モンテカルロ -> 5.コード生成
%   実行時間の目安: 計画1分 + 閉ループ30秒 + MCS 4ラン2分 (+ コード生成数分)
%
%   Falcon9との違い:
%     - ベリー(腹ばい)降下 -> 高度475m付近でフリップ -> 直立着陸 の多フェーズ計画
%     - 制御方式2 (10ms姿勢内ループ + アクチュエータ動特性) を既定で使用
%   全パラメータの意味と一覧は docs/USER_GUIDE.md を参照.
%
%   See also SCPPROBLEM, SCPPLAN, SCPCLOSEDLOOP, SCPMCS, SCPCODEGENZIP,
%            EXAMPLE_FALCON9
here = fileparts(mfilename('fullpath'));
run(fullfile(fileparts(here),'setup.m'));

%% ---- 実行スイッチ (重い節はここで切替) ----
DO.mcs     = true;      % 4. モンテカルロ
DO.codegen = false;     % 5. 組み込みCコード生成 (初回は数分)
DO.anim    = true;     % 3b. 飛行アニメーション
N_MCS      = 20;         % MCSラン数 (精度を見るなら 20-100)
MCS_PAR    = false;     % MCS並列 (初回はプール起動30-60秒)

%% ============ 1. 問題設定 ============
% prob の中身 (すべて編集可):
%   prob.cfg     機体定数            prob.x0      初期状態 (物理単位)
%   prob.phase   ノード->フェーズ番号 (1=ベリー 2=フリップ 3=減速 4=最終)
%   prob.eng     ノード->点火エンジン数 (0=無推力)
%   prob.tiltN   ノード別の傾斜角上限 [rad] (姿勢プロファイルの骨格)
%   prob.opt     計画の許容誤差/重み/制約     prob.track   追従MPCの重み
prob = scpProblem('starship');

% --- 機体諸元を変える場合 (一次諸元 + 派生量, 未指定は自動計算) ---
% prob = scpProblem('starship', struct('dryMass',90e3, 'thrustPerEng',2.5e6, ...
%                                      'Iyy',4.5e7, 'LoverD',0.3));

% --- 初期条件・チューニング例 ---
% prob.x0(1) = 1500;                  % 開始高度 [m]
% prob.opt.wFuel = 35;                % 燃料重視 (フリップが遅くなる)
% prob.sig0 = [10 3.5 4 10];          % 各フェーズ時間の初期推定 [s]

fprintf('--- 1. 問題設定: %s (質量 %.1f t, フェーズ数 %d) ---\n', ...
    prob.vehicle, prob.cfg.m0/1e3, max(prob.phase));

%% ============ 2. 軌道計画 (SCvx) ============
[sol, cfg] = scpPlan(prob);            % results/landing_vert.mat に保存

rE = sol.r(:,end);
fprintf('--- 2. 計画完了: tf=%.1fs 終端(高度%.1fm, 水平%.1fm) 燃料%.2ft ---\n', ...
    sol.tf, rE(1), hypot(rE(2),rE(3)), sol.propellant/1e3);

%% ============ 3. 閉ループ解析 (方式2: 姿勢内ループ + アクチュエータ) ============
% starship は制御方式2が既定:
%   追従MPC(100ms) -> 推力・姿勢コマンド -> 10ms姿勢PD(+FF) -> TVC/スロットル/
%   フラップのアクチュエータ動特性 (2次系6Hz / 1次遅れ) -> プラント
% 方式1 (MPC推力直接) にするには prm.ctlMode='direct'.
% 大気は既定で ISA標準大気 (高度で密度変化. 一定密度は機体諸元 atmIsa=0).
% 高度依存の風を与えるには風況プロファイルを設定する (空力が対気速度で評価される):
%   prob.windProf = loadWindProfile('config/wind_shear_example.json');
R = scpClosedLoop(prob, struct('thrEff',0.97, 'windY',0.3));

plotClosedLoop(sol, R.log, cfg);
xE = R.xEnd;
fprintf('--- 3. 閉ループ完了: 接地 t=%.1fs 水平%.2fm 鉛直%.2fm/s 傾斜%.2fdeg ---\n', ...
    R.tEnd, hypot(xE(2),xE(3)), xE(4), acosd(max(-1,1-2*(xE(9)^2+xE(10)^2))));

if DO.anim                             % ノーズコーン+4フラップの機体形状で再生
    fa = figure('Color','w','Name','Starship 着陸'); axA = axes(fa);
    animateVehicleAx(axA, R.log.t, R.log.x, R.log.u, cfg, ...
                     struct('speed',4,'fps',20));
end

%% ============ 4. モンテカルロ解析 ============
% config/dispersions_starship.m (関数形式) から変動を引く. JSON形式でも可.
if DO.mcs
    mcs = scpMCS(prob, 'dispersions_starship', N_MCS, ...
                 struct('parallel', MCS_PAR));
    ok = [mcs.res.ok];
    fprintf('--- 4. MCS完了: %d/%d 成功, 水平 %.1f±%.1fm, 接地速度 %.1f±%.1fm/s ---\n', ...
        nnz(ok), mcs.N, mean([mcs.res.horiz]), std([mcs.res.horiz]), ...
        mean([mcs.res.vTd]), std([mcs.res.vTd]));
end

%% ============ 5. 組み込みCコード生成 ============
if DO.codegen
    zipf = scpCodegenZip();            % 純C/C++ソースのみの zip (詳細は zip 内 README)
    fprintf('--- 5. コード生成完了: %s ---\n', zipf);
end

fprintf('example_starship 完了\n');
