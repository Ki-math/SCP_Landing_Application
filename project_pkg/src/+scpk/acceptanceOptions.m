function opt = acceptanceOptions()
%ACCEPTANCEOPTIONS  SCPK.ACCEPTANCE の既定しきい値.
%
%   maxReintErr  非線形再積分の位置誤差 [m]. 主判定
%   maxVirtCtrl  仮想制御の総量 (スケール後座標). 補助判定なので緩めに取る
%   maxTermPos   終端位置誤差 [m]
%   maxTermVel   終端速度誤差 [m/s]
%   maxTermAng   終端姿勢誤差 [deg]
%   target       終端目標 [rx ry vx vy theta omega]. 空なら終端判定を省く
opt.maxReintErr = 5.0;
opt.maxVirtCtrl = 1.0;
opt.maxTermPos  = 30.0;
opt.maxTermVel  = 3.0;
opt.maxTermAng  = 5.0;
opt.target      = [];
end
