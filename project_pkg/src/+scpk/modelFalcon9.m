function [cfg,der] = modelFalcon9(ov)
%   CFG = MODELFALCON9(OV) は諸元のオーバーライド OV を適用して cfg を組む.
%   一次諸元に加え派生量 (Ixx/Iyy/Izz, rTx, rho, CdAx/CdSide, aeroScale,
%   LoverD, VrefSurf, surfGain, Bflap, kFlapDrag, hmin_m, wMaxDeg) も物理単位で
%   指定できる (未指定は自動計算). 第2出力 DER は使った値. See scpk.model6.
%MODELFALCON9  Falcon 9 級ブースタの機体定数 (汎用化デモ, 公開値ベースの近似).
%
%   CFG = MODELFALCON9() は scpk.model6 と同一のフィールド構成を返す.
%   力学エンジン (scpk.dynamics6) は共通で, 機体は cfg の差し替えだけで変わる
%   のがこのフレームワークのモデルプラグイン方式:
%     - 予測モデルの実体 = dynamics6(x,u,cfg)  (14状態・7制御の剛体6自由度)
%     - 機体の違い       = cfg (質量・推力・空力・アクチュエータ)
%     - 別力学が必要なら  = dynamics6 と同じシグネチャ [f,A,B]=f(x,u,cfg) の
%       関数で置き換える (CasADi 等で生成した関数をここに接続する)
%
%   Falcon 9 はベリーフロップしない (テールファースト降下) ので, フェーズは
%   [コースト -> 3基点火 -> 1基 -> 精密着陸] とし, フリップ相当フェーズは短い
%   姿勢微調整に退化させる. フラップは無し (グリッドフィンのモーメントは
%   本デモでは無視: Bflap=0).
%
%   注意: 着陸解析デモ用の近似値. 実機検証には諸元の精査が必要.
%
%   See also SCPK.MODEL6, SCPK.DYNAMICS6, RUN_MAIN
g0 = 9.80665;  g = 9.81;

sc.L = 1000;  sc.T = 10;  sc.V = 100;  sc.A = sc.V/sc.T;
cfg.sc = sc;

%% --- 機体諸元 (公開値ベースの近似) ---
veh.dryMass      = 25.6e3;      % ブースタ乾燥質量 [kg]
veh.landingProp  = 8e3;         % 着陸用推進薬 [kg]
veh.m0           = veh.dryMass + veh.landingProp;  % (順序保持: 値は後で再計算)
veh.Lb           = 41;          % 全長 [m]
veh.R            = 1.85;        % 半径 [m]
veh.nEngine      = 3;           % 着陸で使う最大基数
veh.thrustPerEng = 845e3;       % Merlin 1D SL [N]
veh.Isp          = 282;         % SL
veh.throttleMin  = 0.57;
veh.throttleMax  = 1.00;
veh.tvcMax       = deg2rad(8);
veh.tvcRate      = deg2rad(20);
veh.flapMax      = deg2rad(40);  veh.flapMin = 0;      % グリッドフィン ±20deg
veh.flapTrim     = deg2rad(20);  veh.flapRate = deg2rad(30); % (箱 [-trim, max-trim])
%% 一次諸元のオーバーライド (GUI等から). 派生量はこの後で再計算される.
%% (veh に無い名前は派生量オーバーライド. veh へは入れない: MEX構造体順序)
if nargin < 1, ov = []; end
if ~isempty(ov)
    fn = fieldnames(ov);
    for i = 1:numel(fn)
        if isfield(veh,fn{i}), veh.(fn{i}) = ov.(fn{i}); end
    end
end
dv = @(name,def) scpk.ovget(ov,name,def);
veh.m0 = veh.dryMass + veh.landingProp;
cfg.veh = veh;
cfg.m0  = veh.m0;
cfg.Fs  = veh.m0*sc.A;

%% --- 慣性 (既定: 中実円柱近似) ---
Ixx = dv('Ixx', 0.5*veh.m0*veh.R^2);
Iyy = dv('Iyy', veh.m0*(3*veh.R^2 + veh.Lb^2)/12);
Izz = dv('Izz', Iyy);
cfg.J    = diag([Ixx Iyy Izz])/(veh.m0*sc.L^2);
cfg.Jinv = diag(1./diag(cfg.J));
cfg.Jphys = diag([Ixx Iyy Izz]);

%% --- 推力 ---
cfg.Tmin1 = veh.thrustPerEng*veh.throttleMin/cfg.Fs;
cfg.Tmax1 = veh.thrustPerEng*veh.throttleMax/cfg.Fs;
cfg.nEng  = veh.nEngine;
cfg.Tmin  = cfg.nEng*cfg.Tmin1;  cfg.Tmax = cfg.nEng*cfg.Tmax1;
cfg.tanGim = tan(veh.tvcMax);
cfg.alpha  = sc.T*sc.A/(veh.Isp*g0);
rTx = dv('rTx', -(veh.Lb/2));
cfg.rT     = [rTx; 0; 0]/sc.L;

cfg.gI = [-g; 0; 0]/sc.A;

%% --- 大気 (既定: ISA標準大気) ---
atmIsa = dv('atmIsa', 1);
hPad   = dv('hPad', 0);
if atmIsa > 0, rhoDef = scpk.isaRho(hPad); else, rhoDef = 1.12; end

%% --- 空力 (細長い円柱, テールファースト) ---
rho = dv('rho', rhoDef);  aeroScale = dv('aeroScale', 1.0);
CdAx = dv('CdAx', 0.8);  CdSide = dv('CdSide', 1.2);
Sx = pi*veh.R^2;  Sy = veh.Lb*2*veh.R;  Sz = Sy;   %#ok<NASGU>
cfg.cx = aeroScale*0.5*rho*CdAx*Sx*sc.V^2/cfg.Fs;
cfg.cy = aeroScale*0.5*rho*CdSide*Sy*sc.V^2/cfg.Fs;
cfg.cz = cfg.cy;
cfg.LoverD = dv('LoverD', 0);  cfg.cL = cfg.LoverD*cfg.cy;
cfg.rho = rho;  cfg.aeroScale = aeroScale;

%% --- グリッドフィン 4枚 (surfMode=2: 軸流でも効く. 概算同定値) ---
%% 同定条件相当: V=240 m/s. 角加速度 [rad/s^2 per rad].
%% ピッチ/ヨーは対向2枚ペア, ロールは4枚差動 (Starship の Bid と同じ構造).
%% フィールド順は model6 と同一にすること (生成MEXが構造体順序に厳密)
cfg.surfMode = 2;
VrefSurf = dv('VrefSurf', 240);
cfg.V2ref = (VrefSurf/sc.V)^2;
Bfin = dv('Bflap', ...
       [ -0.30  +0.30  -0.30  +0.30;      % ロール
         +0.65  +0.65  -0.65  -0.65;      % ピッチ
         -0.65  +0.65  -0.65  +0.65 ]);   % ヨー
surfGain = dv('surfGain', 1);  kFlapDrag = dv('kFlapDrag', 0.5);
cfg.Bflap = surfGain*Bfin*sc.T^2;
cfg.cFlapDrag = kFlapDrag*veh.flapTrim^2/sc.A;

%% --- 数値・制限 ---
cfg.jacStep = 1e-6;  cfg.vEps = 1e-8;  cfg.tEps = 1e-10;
cfg.mhatMin = veh.dryMass/veh.m0;
wMaxDeg = dv('wMaxDeg', 30);  hmin_m = dv('hmin_m', 18);
cfg.wMax = deg2rad(wMaxDeg)*sc.T;
cfg.hmin = hmin_m/sc.L;          % 脚接地時のCG高度 [m]
cfg.atmIsa = atmIsa;             % 大気モデル (1=ISA / 0=一定密度. model6と同順)
cfg.hPad   = hPad;               % パッド標高 [m]
cfg.wOn    = 0;                  % 計画・追従の風FF (scpPlanがwindProfから設定)
cfg.wTabH  = zeros(1,8);         % 風テーブル: 高度 [m] (パッド基準, 8点)
cfg.wTabY  = zeros(1,8);         % クロスレンジ風 [m/s]
cfg.wTabZ  = zeros(1,8);         % ダウンレンジ風 [m/s]

%% --- 実際に使った派生量 (物理単位, GUI表示用) ---
der = struct('Ixx',Ixx,'Iyy',Iyy,'Izz',Izz,'rTx',rTx,'rho',rho, ...
             'CdAx',CdAx,'CdSide',CdSide,'aeroScale',aeroScale, ...
             'LoverD',cfg.LoverD,'VrefSurf',VrefSurf,'surfGain',surfGain, ...
             'kFlapDrag',kFlapDrag,'hmin_m',hmin_m,'wMaxDeg',wMaxDeg, ...
             'atmIsa',atmIsa,'hPad',hPad);
end
