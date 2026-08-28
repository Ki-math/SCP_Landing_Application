function cfg = model(aeroScale)
%MODEL  平面6-DoF (面内並進 + ピッチ) 終端フェーズのコンフィグ.
%  状態 x = [rx; rz; vx; vz; th; om; mh]
%    rx: 高度[/L], rz: 水平[/L], v: 速度[/V], th: 機体軸の鉛直からの角度[rad],
%    om: ピッチ角速度[rad/無次元時間], mh: m/m0
%  制御 u = [Tx; Tz; df]  Tx,Tz: 機体軸系の推力成分[/(m0*A)], df: フラップ差動[-1,1]
%  スラック s = Gam  (ロスレス凸化: ||[Tx;Tz]|| <= Gam, Tmin <= Gam <= Tmax)
%  推力を力の単位で持つため推力境界が定数になり, 質量方程式も線形になる.
here = fileparts(mfilename('fullpath')); root = fileparts(here);
run(fullfile(root,'source','param.m'));   %#ok<*NODEF>
veh = scpVehicle(); av = attVehicle();
% 空力係数の一括スケール. 既定 0.417 は param.m の CdS=1116 m^2 (終端速度 45 m/s) を
% 実機相当の CdS=465 m^2 (終端速度 70 m/s) に合わせる係数. 1 を渡せば param.m のまま.
if nargin < 1 || isempty(aeroScale), aeroScale = 0.417; end
g0 = 9.80665; m0 = veh.mFlip;
sc.L = 1000; sc.T = 10; sc.V = sc.L/sc.T; sc.A = sc.L/sc.T^2; sc.m = m0;
Fs = m0*sc.A;                                  % 推力のスケール [N]
cfg.sc = sc; cfg.Fs = Fs; cfg.m0 = m0;
cfg.g  = -g/sc.A;
% --- 空力 (成分抗力モデル: 機体軸/側面 それぞれの成分に比例) ---
cfg.cx = aeroScale*0.5*rho*Cd*Sx*sc.V^2/Fs;
cfg.cy = aeroScale*0.5*rho*Cd*Sy*sc.V^2/Fs;
% --- TVC モーメント係数 ---
cfg.cT = Fs*av.tvcArm*sc.T^2/av.Iyy;
% --- ジンバル中立時のピッチバイアス ---
% プラントは My = r1x*Fz - r1z*T*c11 - r2z*T*c21 + r3z*T*c31 = r1x*Fz - T_1基
% 左右エンジンが -1, 下エンジンが +1 の z オフセットを持つため.
% 実測で確認済 (Th=0.4 で -0.0219 rad/s^2, 解析予測 -0.02175).
% バイアス基準係数 (全推力1単位あたり). 実際の係数は基数で決まる:
%   3基 (左右+下): My_bias = -T_1基 = -T_total/3  -> cB = cBunit/3
%   2基 (左右のみ): 下エンジンの +1 が消え My_bias = -T_total -> cB = cBunit
cfg.cBunit = Fs*sc.T^2/av.Iyy;
cfg.cB = cfg.cBunit/3;
% --- フラップ差動モーメント係数 (df=1 で後フラップ全開相当) ---
Kf = aeroScale*2*S_rear_flap*CD_df_rear*av.flapArmR*av.flapMax;
% --- フラップの軸方向抗力 (プラント実測で同定) ---
% smLanderModel.mlx は Force_b(1)=0 としているが, 実機プラントではフラップが
% 軸方向にも力を出す (ベリーフロップ V=70m/s, 舵角40deg で -2.59 m/s^2).
% 舵角の2乗則でよく合う. 対称舵角はトリム固定を前提とする.
cfg.flapTrim  = deg2rad(40);
cfg.cFlapDrag = (4.9018/(0.5*rho*70^2)) * (0.5*rho*sc.V^2) / sc.A;
cfg.cf = 0.5*rho*sc.V^2*Kf*sc.T^2/av.Iyy;
% --- 推進 ---
cfg.alpha = sc.T*sc.A/(veh.Isp*g0);            % dmh/dtau = -alpha*Gam
cfg.Tmin1 = veh.thrustPerEng*veh.throttleMin/Fs;   % 1基あたり
cfg.Tmax1 = veh.thrustPerEng*veh.throttleMax/Fs;
cfg.nEng  = veh.nEngine;
cfg.Tmin  = cfg.nEng*cfg.Tmin1;  cfg.Tmax = cfg.nEng*cfg.Tmax1;
cfg.tanGim = tan(av.tvcMax);
% --- 制限 ---
cfg.omMax  = deg2rad(45)*sc.T;
cfg.hmin   = (L/2)/sc.L;
cfg.mdry   = veh.dryMass/m0;
cfg.dfRate = av.flapRate/av.flapMax*sc.T;      % df の無次元変化率上限 [1/無次元時間]
% Tz = T*sin(eta) の変化率上限. eta_dot = tvcRate [rad/s] より
% dTz/dtau = Tmax*cos(eta)*eta_dot*sc.T.  cos(eta)>=cos(tvcMax) で保守側に取る.
cfg.TzRate = cfg.Tmax*cos(av.tvcMax)*av.tvcRate*sc.T;
cfg.veh = veh; cfg.av = av; cfg.aeroScale = aeroScale;
end



