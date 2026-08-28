function opt = planOptions6()
%PLANOPTIONS6  6自由度 多フェーズ着陸 SCP の既定設定 (許容誤差ベース).
%
%   重みではなく許容誤差で問題を記述する. 各量を許容誤差で割った座標で解くので
%   Hessian はほぼ単位行列になり cond(P) が O(1) に収まる.
%
%   See also SCPK.PLAN6FT, SCPK.BUILDPLAN6

%% --- 許容誤差 (1単位ずれたら同じくらい困る量) ---
opt.tol.pos   = 5;           % [m]
opt.tol.vel   = 0.5;         % [m/s]
opt.tol.quat  = 0.005;       % 四元数成分 (小角で約 0.57 deg)
opt.tol.rate  = 2;           % [deg/s]
opt.tol.mass  = 100;         % [kg]
opt.tol.thr   = 20e3;        % [N]
opt.tol.flap  = deg2rad(2);  % [rad]
opt.tol.sig   = 1;           % 時間膨張 [s]

%% --- 目的とペナルティ ---
opt.wFuel   = 1;             % 終端質量最大化
opt.wCtrl   = 0.02;          % 制御努力
opt.wTilt   = 0;             % 傾斜の2次正則化 (直立想定ノード tiltN<=20deg の
                             % 四元数 q3,q4 に適用, 許容誤差単位). 0だとコストが
                             % 傾斜に無関心になり, 鉛直降下できる場面でも傾いた
                             % 局所解に落ちうる (falcon9で実測 12.8deg).
                             % 目安 0.05-0.5. divertはlamTermが勝つので阻害しない
opt.lamVC   = 1e6;           % 仮想制御 L1 (厳密ペナルティ)
opt.lamTerm = 1e3;           % 終端条件 L1
opt.reg     = 1e-2;          % 全変数への一様正則化 (平坦方向を消す)

%% --- トラストリージョン (境界方式, 許容誤差単位) ---
%% ペナルティにすると線形化が悪い場面で解が遠くへ飛び, rho が負になって
%% 棄却の連鎖に陥る. 境界なら「どれだけ動いてよいか」が陽に決まる.
%% 箱制約なので PIPG では追加コストがゼロ.
opt.trX   = 20;              % 状態の変化幅
opt.trU   = 10;              % 制御の変化幅
opt.trSig = 2;               % 時間膨張の変化幅
opt.wTR   = 0;               % ペナルティ方式は使わない
opt.wTRsig = 0;
opt.trShrinkRate = 0.80;     % 反復ごとの収縮率
opt.trXmin   = 0.5;          % 収縮の下限
opt.trUmin   = 0.3;
opt.trSigMin = 0.05;

%% --- 終端条件と制約 ---
opt.tolBox  = [2 2 2, 1 1 1, 0.02 0.02 0.02, 2 2 2];
opt.hMargin = 20;            % 高度下限の余裕 [m]
opt.phaseTight = 3;          % このフェーズ以降で厳しい制約
opt.wMaxFlip   = deg2rad(60);
opt.wMaxTight  = deg2rad(10);
opt.tiltMax    = deg2rad(10);
opt.glideSlope = deg2rad(20);
opt.nCone   = 25;
opt.coneHalf = deg2rad(25);
opt.coneShrink = 0.99;
opt.lcTol   = 0.05;

%% --- 自由終端時刻 ---
opt.rateLim = true;          % アクチュエータレート制約 (舵面 flapRate, 推力方向
                             % tvcRate の小角近似) をノード間の制御変化に課す
opt.sigMin  = 0.5;           % 各フェーズの時間下限 [s] (スカラーまたはフェーズ別)
opt.sigMax  = 30;            % 上限 [s]

%% --- SCP 反復 ---
opt.maxIter  = 15;
opt.tolStep  = 1e-2;
opt.nSub     = 10;           % defect 評価の RK4 分割数
opt.nSubInit = 8;            % 初期線形化点を作る RK4 分割数
opt.adaptTR  = false;        % 境界方式なので適応制御は使わない
opt.rho0 = 0.0; opt.rho1 = 0.25; opt.rho2 = 0.7;
opt.trShrink = 2.0; opt.trExpand = 0.5;
opt.wTRmin = 0.05; opt.wTRmax = 500;

opt.qp = scpk.qpOptions();
opt.qp.maxIter = 8000;
opt.qp.omega   = 1e5;
opt.qp.tolPri  = 1e-4;
opt.qp.tolDua  = 1e-4;
opt.verbose = false;
end

