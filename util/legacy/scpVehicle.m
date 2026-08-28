function veh = scpVehicle()
%SCPVEHICLE  誘導設計に用いる機体諸元 (実機相当).
%  形状・空力は source/param.m を使い, 質量と推進系のみここで実機相当に置き換える.
%  source/param.m 側は既存の NLMPC ベースラインと MCS 結果を保つため変更しない.
%  Simulink 統合の段階で両者を意図的に同期させること.
veh.dryMass      = 85e3;      % 乾燥質量 [kg]
veh.landingProp  = 45e3;      % 着陸用推進薬 [kg]
veh.mFlip        = veh.dryMass + veh.landingProp;   % フリップ開始時質量 [kg]
veh.nEngine      = 3;
veh.thrustPerEng = 2.30e6;    % 海面推力 [N] (ラプター級)
veh.throttleMin  = 0.40;      % 深絞り限界
veh.throttleMax  = 1.00;
veh.Isp          = 330;       % 海面比推力 [s]
veh.Tmax = veh.nEngine*veh.thrustPerEng*veh.throttleMax;
veh.Tmin = veh.nEngine*veh.thrustPerEng*veh.throttleMin;
end
