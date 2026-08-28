function cfg = model6Paper()
%MODEL6PAPER  Lee, Jung & Lee (2025) の論文機体パラメータ (Table 1-2, SI単位).
%
%   論文の解析条件を厳密に再現するための定数. 現行 model6 (実機校正・130 t) とは
%   別物で, 論文機体 (100 t・楕円体空力・基数3→1) を表す.
%
%   規約: 慣性系 = ENU (Up = 第3成分 Z_I), 機体 Z_B = 機首方向.
%         状態 x = [m; rI(3); vI(3); qB(4); wB(3)]  (質量先頭, 速度は慣性系)
%         制御 u = T_B(3)  (機体系推力ベクトル)
%
%   注意: 空気密度 rho は論文 Table 1 に無いため標準大気 1.225 kg/m^3 を仮定.
%         この値では論文図8の終端速度に完全には一致しない (既知の限界).
%
%   See also SCPK.DYNAMICS6PAPER
cfg.g0    = 9.81;      % [m/s^2]
cfg.Isp   = 330;       % [s]
cfg.Lr    = 4.5;       % 半径 [m]
cfg.Lh    = 50;        % 全高 [m]
cfg.Lcm   = 20;        % ノズル-重心 [m] (rT,B = [0;0;-Lcm])
cfg.Lcp   = 10;        % 圧力中心-重心 [m] (rA,B = [0;0;+Lcp])
cfg.SA    = 63.62;     % 基準面積 [m^2]
cfg.Caxy  = 0.4068;    % 空力係数 (側面/ベリー)
cfg.Caz   = 0.0522;    % 空力係数 (軸方向)
cfg.rho   = 1.225;     % 空気密度 [kg/m^3] (論文未記載, 標準大気を仮定)
cfg.m0    = 100e3;     % 初期質量 [kg]
cfg.mdry  = 85e3;      % 乾燥質量 [kg]
cfg.Tmin  = 880e3;     % 1基最小推力 [N]
cfg.Tmax  = 2200e3;    % 1基最大推力 [N]
cfg.deltaMax = deg2rad(15);   % TVC最大 [rad]
cfg.etaMax   = deg2rad(10);   % 傾斜角最大 [rad]
cfg.wMax     = deg2rad(10);   % 角速度最大 [rad/s]
cfg.gammaGs  = deg2rad(20);   % グライドスロープ [rad]
cfg.muT   = 0.05;     % 推力マージン
cfg.muA   = 0.2;      % TVCマージン
cfg.hL    = 100;      % 精密着陸フェーズ開始の最小高度 [m]
cfg.tEps  = 1e-6;     % 推力ノルム平滑化
cfg.jacStep = 1e-6;   % 中心差分刻み
end
