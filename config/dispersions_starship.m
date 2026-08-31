function spec = dispersions_starship()
%DISPERSIONS_STARSHIP  MCS の変動パラメータ定義 (Starship 着陸シナリオ).
%
%   各行: {パラメータ名, 分布, p1, p2}
%     'uniform' : [p1, p2] の一様分布
%     'normal'  : 平均 p1, 標準偏差 p2 (打ち切りなし)
%     'normal3' : 平均 p1, 標準偏差 p2 を ±3σ で打ち切り (推奨)
%
%   使える名前:
%     環境・初期分散: thrEff / windY / navJump / dr0x dr0y dr0z (初期位置[m]) /
%                     dvBx dvBy dvBz (初期速度[m/s], 機体系)
%     機体諸元 (プラント側モデルのみ差し替え = モデル誤差ロバスト性の評価):
%                     dryMass, landingProp, Isp, thrustPerEng, Ixx/Iyy/Izz,
%                     rTx, rho, CdAx, CdSide, aeroScale, LoverD, surfGain など
%                     (USER_GUIDE §6-§7 参照. 値は絶対値で指定)
%
%   See also SCPMCS, RUNMCS_SCP, RUNCLOSEDLOOPREPLAN
spec = { ...
    ... 環境・初期分散
    'thrEff',   'uniform', 0.95,   1.00 ;   % 推力効率 (モデル誤差)
    'windY',    'normal3', 0.0,    0.4  ;   % 横風加速度 [m/s^2]
    'dr0x',     'normal3', 0.0,    15   ;   % 初期高度オフセット [m]
    'dr0y',     'normal3', 0.0,    50   ;   % 初期クロスレンジ [m]
    'dr0z',     'normal3', 0.0,    50   ;   % 初期ダウンレンジ [m]
    'dvBx',     'normal3', 0.0,    1.5  ;   % 初期速度 (機体x) [m/s]
    'dvBy',     'normal3', 0.0,    1.0  ;
    'dvBz',     'normal3', 0.0,    1.5  ;
    ... 機体諸元 (公称: dryMass 85e3, Isp 330, aeroScale 0.417)
    'dryMass',  'normal3', 85e3,   850  ;   % 乾燥質量 ±1% (1σ) [kg]
    'Isp',      'normal3', 330,    1.5  ;   % 比推力 [s]
    'aeroScale','normal3', 0.417,  0.02 ;   % 空力スケール (~±5%/1σ. 密度誤差も包含)
    'windScale','normal3', 1.0,    0.15 ;   % 風況プロファイル乗率 (windProf設定時のみ有効)
    };
%% 注: 'rho' の変動は一定密度モード (atmIsa=0) でのみ意味を持つ.
%%     ISA (既定) では密度は高度から決まり rho は基準値として相殺される.
end
