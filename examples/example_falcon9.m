%EXAMPLE_FALCON9  Falcon9級ブースタ着陸の通しワークフロー.
%
%   >> setup            (初回のみ. パス設定)
%   >> example_falcon9
%
%   流れ: 1.問題設定 -> 2.軌道計画 -> 3.閉ループ -> 4.モンテカルロ -> 5.コード生成
%   実行時間の目安: 計画1分 + 閉ループ20秒 + MCS 4ラン1.5分 (+ コード生成数分)
%
%   各節のパラメータはすべて編集して再実行できる. 全パラメータの意味と一覧は
%   docs/USER_GUIDE.md を参照.
%
%   See also SCPPROBLEM, SCPPLAN, SCPCLOSEDLOOP, SCPMCS, SCPCODEGENZIP,
%            EXAMPLE_STARSHIP
here = fileparts(mfilename('fullpath'));
run(fullfile(fileparts(here),'setup.m'));

%% ---- 実行スイッチ (重い節はここで切替) ----
DO.mcs     = true;      % 4. モンテカルロ (N_MCS ラン)
DO.codegen = false;     % 5. 組み込みCコード生成 (初回は数分. 生成物があれば数秒)
DO.anim    = true;     % 3b. 飛行アニメーション
N_MCS      = 100;         % MCSラン数 (精度を見るなら 20-100)
MCS_PAR    = true;     % MCS並列 (Parallel Computing Toolbox. 初回はプール起動30-60秒)

%% ============ 1. 問題設定 ============
% scpProblem がテンプレート機体の「問題定義」一式を返す. 全フィールド編集可.
%   prob.cfg     機体定数 (力学モデル dynamics6 が参照)
%   prob.x0      初期状態 [高度;クロス;DR; vB(3); 四元数(4); 角速度(3); 質量]
%   prob.opt     計画の許容誤差(tol.*)/重み/制約  (一覧: docs/USER_GUIDE.md §4)
%   prob.track   追従MPCの重み                    (一覧: docs/USER_GUIDE.md §5)
prob = scpProblem('falcon9');

% --- 機体諸元を変える場合 (第2引数に一次諸元/派生量のオーバーライド) ---
% prob = scpProblem('falcon9', struct( ...
%     'dryMass',22e3, 'landingProp',6e3, ...   % 一次諸元 [kg]
%     'Iyy',4.2e6, 'rTx',-19, ...              % 派生量 (未指定は自動計算)
%     'hmin_m',15));                           % 脚接地時のCG高度 [m]

% --- 初期条件を変える場合 (物理単位) ---
prob.x0(1) = 2000;      % 高度 [m]
prob.x0(3) = 0;       % ダウンレンジ [m] (パッド=0)
prob.x0(6) = 0;        % 水平速度 [m/s] (機体系z)

% --- 計画チューニングを変える場合 (代表例) ---
% prob.opt.wFuel   = 25;              % 燃料重視度
% prob.opt.wTilt   = 0.1;             % 傾斜正則化 (falcon9既定 0.1)
prob.opt.tol.pos = 10;               % 位置スケーリング [m] (小さい=位置を重視)
prob.track.wPos  = 32;               % inner方式で着地点への収束を強化
% prob.tiltN(:)    = deg2rad(8);      % 傾斜角スケジュール上限 [rad]

% 風モデル
% 風速 [m/s] は windProf で与える. MCS の windScale はこのプロファイルを倍率変動させる.
prob.windProf = loadWindProfile('config/wind_shear_example.json');

fprintf('--- 1. 問題設定: %s (質量 %.1f t, エンジン %d基) ---\n', ...
    prob.vehicle, prob.cfg.m0/1e3, prob.cfg.nEng);

%% ============ 2. 軌道計画 (SCvx) ============
% コールドスタート + 多段求解 (prob.passes: 緩->厳の順に解き直す継続法) を自動実行し,
% results/landing_falcon9.mat に保存する. 出力 sol の主なフィールド:
%   sol.t / sol.r / sol.v / sol.q / sol.w  時刻と状態履歴 (物理単位)
%   sol.uhat / sol.Tmag                    制御と推力の大きさ
%   sol.sigma                              各フェーズの時間 [s]
[sol, cfg] = scpPlan(prob);

rE = sol.r(:,end);
fprintf('--- 2. 計画完了: tf=%.1fs 終端(高度%.1fm, 水平%.1fm) 燃料%.2ft ---\n', ...
    sol.tf, rE(1), hypot(rE(2),rE(3)), sol.propellant/1e3);

%% ============ 3. 閉ループ解析 (追従MPC + 外乱) ============
% 計画を参照に 100ms周期の追従MPC + 10ms周期の速度FB/プラントで飛ばす.
% 第2引数 prm で外乱・初期オフセットを指定する (すべて省略可):
%   thrEff   推力効率 (実推力 = 計画推力 x thrEff. 1.0=公称)
%   windY    横風の等価加速度 [m/s^2]
%   navJump  t=8s の航法ジャンプ [m] (0=なし)
%   dr0      初期位置オフセット [高度;クロス;DR] [m]
%   dvB0     初期速度オフセット (機体系) [m/s]
%   errTrig  オンライン再計画のトリガ誤差 [m] (inf=再計画なし)
%   windProf 高度依存の風況プロファイル (prob.windProf =
%            loadWindProfile('config/wind_shear_example.json') でも指定可)
% 誘導は姿勢コマンドを生成し, 姿勢内ループとアクチュエータ動特性を介して飛行する.
% 本評価モデルの内ループはPD近似で, 実機PIDとの接続境界は姿勢コマンド qCmd.
prob.ctlMode = 'inner';
R = scpClosedLoop(prob, struct('thrEff',0.97, 'windY',0.2));

plotClosedLoop(sol, R.log, cfg);        % 計画 vs 閉ループ の6面図
xE = R.xEnd;
fprintf('--- 3. 閉ループ完了: 接地 t=%.1fs 水平%.2fm 鉛直%.2fm/s 傾斜%.2fdeg ---\n', ...
    R.tEnd, hypot(xE(2),xE(3)), xE(4), acosd(max(-1,1-2*(xE(9)^2+xE(10)^2))));

if DO.anim                              % 飛行アニメーション (フィン/脚展開つき)
    fa = figure('Color','w','Name','Falcon9 着陸'); axA = axes(fa);
    animateVehicleAx(axA, R.log.t, R.log.x, R.log.u, cfg, ...
                     struct('style','falcon9','speed',1.5,'fps',20));
end

%% ============ 4. モンテカルロ解析 (ロバスト性評価) ============
% 変動定義ファイル (config/dispersions_falcon9.json) に従って外乱・初期分散を
% 引き, 閉ループを N 回実行して着陸精度の統計をとる.
% 変動定義の書式: {"name":"thrEff","dist":"uniform","p1":0.97,"p2":1.0} など.
% 使える名前: thrEff, windY, navJump, dr0x/y/z, dvBx/y/z ほか (USER_GUIDE §6).
if DO.mcs
    mcs = scpMCS(prob, 'dispersions_falcon9.json', N_MCS, ...
                 struct('parallel', MCS_PAR));
    ok = [mcs.res.ok];
    fprintf('--- 4. MCS完了: %d/%d 成功, 水平 %.1f±%.1fm, 接地速度 %.1f±%.1fm/s ---\n', ...
        nnz(ok), mcs.N, mean([mcs.res.horiz]), std([mcs.res.horiz]), ...
        mean([mcs.res.vTd]), std([mcs.res.vTd]));
end

%% ============ 5. 組み込みCコード生成 ============
% 計画SCP 1反復のフルC + PIPGソルバ単体 + サンプルmain + README を
% 純C/C++ソースのみの zip に固める (MATLAB/MEX/BLAS 依存ゼロ).
% ターゲット環境では gcc -O2 -Iplanner -Iexamples examples/main_planner_example.c
% planner/*.c -lm でビルドできる. 詳細は zip 内 README.md.
if DO.codegen
    zipf = scpCodegenZip();             % scpCodegenZip(true) で完全再生成 (数分)
    fprintf('--- 5. コード生成完了: %s ---\n', zipf);
end

fprintf('example_falcon9 完了\n');
