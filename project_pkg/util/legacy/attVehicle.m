function v = attVehicle()
%ATTVEHICLE  姿勢制御用の機体諸元 (source/param.m + scpVehicle.m から構成).
%  座標: 平面ピッチ. theta = 機体軸の鉛直上向きからの角度.
%        theta = 90deg -> ベリーフロップ,  theta = 0 -> テールダウン(エンジン下向き).
%  迎角 alpha = 機体軸と速度ベクトルのなす角. 速度が真下なら alpha = 180 - theta.
here = fileparts(mfilename('fullpath')); root = fileparts(here);
run(fullfile(root,'source','param.m'));   %#ok<*NODEF>
veh = scpVehicle();
v.m    = veh.mFlip;
v.L    = L; v.R = radius;
v.Iyy  = (radius^2/4 + L^2/12)*v.m;
v.g    = 9.81;  v.rho = rho;  v.Cd = Cd;
v.Sx   = Sx;  v.Sy = Sy;                 % 軸方向/側面 の代表面積
% --- フラップ ---
v.flapArmF = abs(L/2 - (12+2.2));
v.flapArmR = abs((L-8+2.83) - L/2);
v.kF = 2*S_front_flap*CD_df_front;        % 前2枚の合計 CdS/rad
v.kR = 2*S_rear_flap*CD_df_rear;          % 後2枚の合計
v.flapMin = 0; v.flapMax = deg2rad(80);
v.flapRate = Flap_rate_lim;               % 15 deg/s
v.flapWn = Flap_wn; v.flapZeta = Flap_zeta;
% --- TVC ---
% smLanderModel.mlx / プラント実測に一致させる (r1x = L/2+1.5)
v.tvcArmModel = L/2 - 1;   % 旧値 (誤り)
v.tvcArm  = L/2 + 1.5;
% --- 実機相当への置換 (source/param.m は既存ベースライン保持のため変更しない) ---
v.tvcMaxModel = TVC_max;                  % param.m の値 (7 deg)
v.tvcMax  = deg2rad(15);                  % 実機相当. 7deg では着陸が成立しないことを確認済み
v.tvcRate = TVC_rate_lim;                 % 20 deg/s
v.tvcWn = TVC_wn; v.tvcZeta = TVC_zeta;
v.Tmax = veh.Tmax; v.Tmin = veh.Tmin;
v.veh = veh;
end

