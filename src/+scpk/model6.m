function [cfg,der] = model6(ov)
%   CFG = MODEL6(OV) は諸元のオーバーライド OV (struct) を適用して cfg を組む.
%   OV には一次諸元 (dryMass, thrustPerEng, ...) に加えて, 従来自動計算だった
%   派生量も物理単位で指定できる (未指定は自動計算):
%     Ixx, Iyy, Izz [kg m^2]   慣性モーメント (既定: 中実円柱近似)
%     rTx [m]                  推力作用点の機体x座標 (既定: -(Lb/2+1.5))
%     rho [kg/m^3]             大気密度 (既定 1.12)
%     CdAx, CdSide             軸/横 抗力係数 (既定 2.0/2.0)
%     aeroScale                空力全体スケール (既定 0.417, 実測補正)
%     LoverD                   ベリー時の揚抗比 (既定 0.25)
%     VrefSurf [m/s]           舵面効き同定速度 (既定 70)
%     surfGain                 舵面効きゲイン (Bflapに乗算, 既定 1)
%     Bflap [3x4]              舵面効き行列そのもの [rad/s^2 per rad]
%     kFlapDrag                舵面軸抗力係数 (既定 4.9018)
%     hmin_m [m]               脚接地時のCG高度 (既定 31)
%     wMaxDeg [deg/s]          角速度上限 (既定 30)
%   第2出力 DER は実際に使った派生量 (物理単位) を返す (GUI表示用).
%   例: cfg = scpk.model6(struct('dryMass',90e3,'Iyy',5.0e7));
%MODEL6  スターシップ帰還6自由度モデルの定数 (無次元化済み).
%
%   CFG = MODEL6() は SCPK.DYNAMICS6 が使う定数と, 問題定義に必要な機体制限を
%   返す. すべて無次元量で, スケールは CFG.sc に入る.
%
%   無次元化   長さ L=1000 m, 時間 T=10 s, 速度 V=100 m/s, 加速度 A=10 m/s^2
%              質量 m0 (着陸開始質量), 力 Fs = m0*A
%
%   慣性系は [高度; クロスレンジ; ダウンレンジ]. 四元数は R(q) が慣性 -> 機体
%   (Reb, smLanderModel.mlx と同じ規約) で, プラントのセンサバスと整合する.
%
%   空力とフラップ効きは実測同定値に基づく. SMLANDERMODEL.MLX の解析式は
%   プラント (Simscape + aerolib) と一致しない (ピッチ 0.63倍, ロール 0.30倍,
%   軸方向抗力の欠落). 詳細は CTL.CONSTANTS のヘルプを参照.
%
%   See also SCPK.DYNAMICS6, CTL.CONSTANTS
g0 = 9.80665;  g = 9.81;

%% --- スケール ---
sc.L = 1000;  sc.T = 10;  sc.V = 100;  sc.A = sc.V/sc.T;
cfg.sc = sc;

%% --- 機体諸元 (実機相当) ---
veh.dryMass      = 85e3;        %% 乾燥質量 [kg]
veh.landingProp  = 45e3;        %% 着陸用推進薬 [kg]
veh.m0           = veh.dryMass + veh.landingProp;  %% (順序保持: 値は後で再計算)
veh.Lb           = 62;          %% 全長 [m]
veh.R            = 4.5;         %% 半径 [m]
veh.nEngine      = 3;
veh.thrustPerEng = 2.30e6;      %% 1基あたり [N]
veh.Isp          = 330;
veh.throttleMin  = 0.40;
veh.throttleMax  = 1.00;
veh.tvcMax       = deg2rad(15); %% ジンバル最大角
veh.tvcRate      = deg2rad(20); %% ジンバル角速度 [rad/s]. 計画のレート制約で使用.
                                %% プラント側スルーレート飽和 (prm.actRateLim=true) を
                                %% 使う場合, 方式2のフリップ制動成立には 40deg/s 以上
                                %% が必要 (30deg/s以下は閉ループ発散, 実測)
veh.flapMax      = deg2rad(80);
veh.flapMin      = 0;
veh.flapTrim     = deg2rad(40);
veh.flapRate     = deg2rad(15); %% フラップ角速度上限 [rad/s]. 計画のレート制約で使用.
                                %% プラント側スルーレート飽和 (prm.actRateLim=true) を
                                %% 使う場合, ベリー姿勢保持には 30deg/s 以上が必要
                                %% (25deg/s以下は閉ループ不安定, 実測)
%% 一次諸元のオーバーライド (GUI等から). 派生量はこの後で再計算される.
%% (veh に無い名前は派生量オーバーライドなので dv() 側で扱う. veh へは入れない:
%%  cfg構造体のフィールド構成は生成MEXと厳密一致が必要)
if nargin < 1, ov = []; end
if ~isempty(ov)
    fn = fieldnames(ov);
    for i = 1:numel(fn)
        if isfield(veh,fn{i}), veh.(fn{i}) = ov.(fn{i}); end
    end
end
dv = @(name,def) scpk.ovget(ov,name,def);   %% 派生量: 指定があればそれ, 無ければ自動計算
veh.m0 = veh.dryMass + veh.landingProp;
cfg.veh = veh;
cfg.m0  = veh.m0;
cfg.Fs  = veh.m0*sc.A;

%% --- 慣性 (既定: 中実円柱近似. プラント実測のロール応答と 1%% 以内で一致) ---
Ixx = dv('Ixx', 0.5*veh.m0*veh.R^2);
Iyy = dv('Iyy', veh.m0*(3*veh.R^2 + veh.Lb^2)/12);
Izz = dv('Izz', Iyy);
cfg.J    = diag([Ixx Iyy Izz])/(veh.m0*sc.L^2);   %% 無次元慣性
cfg.Jinv = diag(1./diag(cfg.J));
cfg.Jphys = diag([Ixx Iyy Izz]);

%% --- 推力 ---
cfg.Tmin1 = veh.thrustPerEng*veh.throttleMin/cfg.Fs;   %% 1基あたり (無次元)
cfg.Tmax1 = veh.thrustPerEng*veh.throttleMax/cfg.Fs;
cfg.nEng  = veh.nEngine;
cfg.Tmin  = cfg.nEng*cfg.Tmin1;
cfg.Tmax  = cfg.nEng*cfg.Tmax1;
cfg.tanGim = tan(veh.tvcMax);
cfg.alpha  = sc.T*sc.A/(veh.Isp*g0);                  %% dmhat/dtau = -alpha*||T||
rTx = dv('rTx', -(veh.Lb/2 + 1.5));                   %% 推力作用点 (実測 r1x=32.5 m)
cfg.rT     = [rTx; 0; 0]/sc.L;

%% --- 重力 ---
cfg.gI = [-g; 0; 0]/sc.A;

%% --- 大気 (既定: ISA標準大気) ---
atmIsa = dv('atmIsa', 1);       %% 1=ISA標準大気 (高度で密度が変化) / 0=一定密度
hPad   = dv('hPad', 0);         %% 着陸パッドの標高 [m] (ISAの基準高度)
if atmIsa > 0, rhoDef = scpk.isaRho(hPad); else, rhoDef = 1.12; end

%% --- 空力 (実機相当. param.m の Cd=2, CdS=1116 m^2 を 0.417 倍に補正) ---
rho = dv('rho', rhoDef);  aeroScale = dv('aeroScale', 0.417);
CdAx = dv('CdAx', 2.0);  CdSide = dv('CdSide', 2.0);
Sx = pi*veh.R^2;                 %% 軸方向 (テールオン)
Sy = veh.Lb*2*veh.R;             %% 側面 (ベリーオン)
Sz = Sy;
cfg.cx = aeroScale*0.5*rho*CdAx*Sx*sc.V^2/cfg.Fs;
cfg.cy = aeroScale*0.5*rho*CdSide*Sy*sc.V^2/cfg.Fs;
cfg.cz = aeroScale*0.5*rho*CdSide*Sz*sc.V^2/cfg.Fs;
%% 揚力係数. ベリーフロップ (迎角90deg) での L/D = 0.25 になるよう定める.
%% 抗力は cy*V*vz (機体z方向), 揚力は cL*V*vz (機体-x方向) なので cL = 0.25*cy.
cfg.LoverD = dv('LoverD', 0.25);
cfg.cL = cfg.LoverD*cfg.cy;
cfg.rho = rho;  cfg.aeroScale = aeroScale;

%% --- フラップ (実測同定値) ---
%% acc = Bflap * d, 動圧と |sin(alpha)| でスケール. d はトリムからの偏差 [rad]
%% 同定条件: ベリーフロップ, V=70 m/s, トリム 40 deg
Bid = dv('Bflap', ...
      [ -0.7645  +0.7645  -1.7861  +1.7861;      %% ロール [rad/s^2 per rad]
        +0.1072  +0.1072  -0.1762  -0.1762;      %% ピッチ
        -0.0762  +0.0762  -0.2060  +0.2060 ]);   %% ヨー
surfGain = dv('surfGain', 1);  VrefSurf = dv('VrefSurf', 70);
kFlapDrag = dv('kFlapDrag', 4.9018);
cfg.surfMode = 1;                %% 操縦翼面: 1=ベリーフラップ (dynamics6参照)
cfg.V2ref  = VrefSurf^2/sc.V^2;  %% 同定時の速度^2 (無次元)
cfg.Bflap  = surfGain*Bid*sc.T^2;   %% 無次元角加速度へ
cfg.cFlapDrag = kFlapDrag*veh.flapTrim^2/sc.A;   %% 軸方向抗力 (舵角2乗則, 実測)

%% --- 数値パラメータ ---
cfg.jacStep = 1e-6;             %% 中心差分の刻み
cfg.vEps    = 1e-8;             %% 速度ゼロ割り回避
cfg.tEps    = 1e-10;            %% 推力ノルムの平滑化
cfg.mhatMin = veh.dryMass/veh.m0;

%% --- 制限 (問題定義で使う) ---
wMaxDeg = dv('wMaxDeg', 30);  hmin_m = dv('hmin_m', 31);
cfg.wMax   = deg2rad(wMaxDeg)*sc.T;   %% 角速度上限 [無次元]
cfg.hmin   = hmin_m/sc.L;             %% 目標高度 (脚接地時のCG高度)
cfg.atmIsa = atmIsa;                  %% 大気モデル (1=ISA / 0=一定密度)
cfg.hPad   = hPad;                    %% パッド標高 [m]
cfg.wOn    = 0;                       %% 計画・追従の風FF (scpPlanがwindProfから設定)
cfg.wTabH  = zeros(1,8);              %% 風テーブル: 高度 [m] (パッド基準, 8点)
cfg.wTabY  = zeros(1,8);              %% クロスレンジ風 [m/s]
cfg.wTabZ  = zeros(1,8);              %% ダウンレンジ風 [m/s]

%% --- 実際に使った派生量 (物理単位, GUI表示用) ---
der = struct('Ixx',Ixx,'Iyy',Iyy,'Izz',Izz,'rTx',rTx,'rho',rho, ...
             'CdAx',CdAx,'CdSide',CdSide,'aeroScale',aeroScale, ...
             'LoverD',cfg.LoverD,'VrefSurf',VrefSurf,'surfGain',surfGain, ...
             'kFlapDrag',kFlapDrag,'hmin_m',hmin_m,'wMaxDeg',wMaxDeg, ...
             'atmIsa',atmIsa,'hPad',hPad);
end
