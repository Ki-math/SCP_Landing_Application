function topt = track6Options()
%TRACK6OPTIONS  6自由度 追従MPC (100 ms 周期) の既定設定.
%
%   計画層と同じ許容誤差スケーリングで偏差座標のQPを組む. 予測ホライズンは
%   短く (H*dt ~ 1.2 s), 参照軌道まわりのLTV線形化なので凸化の反復は不要
%   (1 QP = 1 制御周期; real-time iteration).
%
%   See also SCPK.TRACK6STEP, SCPK.PLAN6FT
topt.H  = 25;          % 予測ホライズン節点数
topt.dt = 0.2;         % 節点間隔 [s] (ホライズン 5 s; 論文 t_h=5s と同じ)
topt.dtCtrl  = 0.10;   % 追従MPCの実行周期 [s] (閉ループ prm.dtMpc の既定値.
                       %  コード生成例 ex_dtCtrl もここを参照)
topt.dtPlant = 0.01;   % プラント積分・10ms層の刻み [s] (閉ループ prm.dtPlant の既定値)
%% 位置は姿勢経由の二重積分応答なので, 短いホライズンでは位置フィードバックが
%% 実質効かない (1.2 s で実測: 位置誤差が単調増大して墜落).

%% --- 許容誤差 (偏差の無次元化, 計画層より締める) ---
topt.tol.pos  = 2;             % [m]
topt.tol.vel  = 0.3;           % [m/s]
topt.tol.quat = 0.01;
topt.tol.rate = 2;             % [deg/s]
topt.tol.mass = 500;           % [kg] (追従では質量偏差は軽視)
topt.tol.thr  = 50e3;          % [N]
topt.tol.flap = deg2rad(5);

%% --- 重み (許容誤差座標で) ---
topt.wPos  = 8;      % 位置
topt.wVel  = 2;      % 速度
topt.wQuat = 1;      % 姿勢
topt.wRate = 0.5;    % 角速度
topt.wMass = 0;      % 質量は追わない
topt.wTerm = 10;     % 終端ブロック倍率
topt.rCtrl = 0.5;    % 制御偏差
topt.reg   = 1e-3;

%% --- QP (PIPG) ---
topt.useCpp = true;    % 手書きC++ソルバ (pipg_mex) を使う. 未ビルドなら自動で
                       % MATLAB版 solveQP にフォールバック.
topt.fastQP = true;       % 固定反復モード (300回, 決定的 ~9ms). false で従来の
                          % 収束判定モード (高精度だが 20-60ms/回)
topt.qp = scpk.qpOptions();
topt.qp.maxIter = 2500;
topt.qp.omega   = 1e4;    % 許容誤差スケーリングのみの構成での調整値
topt.qp.tolPri  = 1e-3;   % 制御用途では 1e-3 で十分
topt.qp.tolDua  = 1e-3;
end
