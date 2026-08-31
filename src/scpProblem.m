function prob = scpProblem(vehicle, vehOv)
%   PROB = SCPPROBLEM(VEHICLE, VEHOV) は機体一次諸元のオーバーライド VEHOV
%   (dryMass, landingProp, Lb, R, nEngine, thrustPerEng, Isp, throttleMin,
%    tvcMax など) を適用したモデルで問題を組む (GUIの機体諸元編集用).
%SCPPROBLEM  着陸解析の問題定義を生成する (機体・シナリオ・重み・制約の全部入り).
%
%   PROB = SCPPROBLEM('starship')   Starship (ベリーフラップ, フリップ着陸)
%   PROB = SCPPROBLEM('falcon9')    Falcon9級 (グリッドフィン, ホバースラム)
%
%   返り値 PROB は全て編集可能:
%     .cfg        機体定数 (予測モデル = dynamics6(x,u,cfg) が参照)
%                 別力学は dynamics6 と同一シグネチャの関数で差し替える
%     .cfgPlan    計画用 cfg (推力マージン等を計画だけに課す場合に cfg と変える)
%     .x0, .xT    初期状態 (物理) / 終端目標 (無次元12)
%     .phase/.eng/.tiltN/.sig0   フェーズ構成・基数・傾斜スケジュール・初期時間
%     .opt        計画の重み/スケーリング/制約 (planOptions6 形式):
%                   tol.* (スケーリング), wFuel/lamVC/lamTerm/lamGlide (重み),
%                   sigMin/Max, drBox, crMax, monoDescent, softGlide, ... (制約)
%     .passes     チューニング連鎖 (struct配列. 各要素のフィールドが opt を上書き.
%                 .sigma があれば warm start の σ を差し替え)
%     .track      追従MPCの重み/スケール (track6Options 形式)
%     .planFile   計画解の保存名
%
%   使い方:
%     prob = scpProblem('falcon9');
%     prob.opt.lamTerm = 1e8;              % 重みを変える
%     prob.opt.tol.pos = 2;                % スケーリングを変える
%     prob.opt.drBox = [-200 20];          % 制約を変える
%     sol = scpPlan(prob);                 % 計画
%     R = scpClosedLoop(prob, struct());   % 閉ループ
%
%   See also SCPPLAN, SCPCLOSEDLOOP, RUNMCS_SCP, SCPCODEGENZIP
if nargin < 2, vehOv = []; end
switch lower(vehicle)
case 'starship'
    cfg = scpk.model6(vehOv);
    qBelly = eul2quat([0 -pi/2 0],'ZYX').';
    vB0 = quat2dcm(qBelly.')*[-80;0;0];
    prob.cfg = cfg;  prob.cfgPlan = cfg;
    prob.x0 = [1200; 0; -325; vB0; qBelly; 0;0;0; cfg.m0];
    prob.xT = [cfg.hmin; 0;0; 0;0;0; 0;0;0; 0;0;0];
    prob.phase = [1*ones(1,12), 2*ones(1,10), 3*ones(1,12), 4*ones(1,16)];
    prob.eng   = [0*ones(1,12), 3*ones(1,10), 1*ones(1,12), 1*ones(1,16)];
    N = numel(prob.phase);
    tiltN = deg2rad(179)*ones(1,N+1);
    i2=find(prob.phase==2); tiltN(i2(1):i2(end)+1)=deg2rad(linspace(100,30,numel(i2)+1));
    i3=find(prob.phase==3); tiltN(i3(1):i3(end)+1)=deg2rad(linspace(30,10,numel(i3)+1));
    i4=find(prob.phase==4); tiltN(i4(1):N+1)=deg2rad(10);
    prob.tiltN = tiltN;
    prob.sig0 = [9 3.5 4 10];
    o = scpk.planOptions6();
    o.qBelly=qBelly; o.bellyHold=2; o.softGlide=true;
    o.wMaxFlip=deg2rad(30); o.wMaxTight=deg2rad(10);
    o.sigMin=[8 3 2 4]; o.sigMax=[10 4 5 20];
    o.lamTerm=2e6; o.lamGlide=2e5; o.thrMaxTight=0.9; o.phaseTight=4;
    o.trShrinkRate=0.93; o.trXmin=3; o.trUmin=2; o.trSigMin=0.3;
    o.maxIter=24; o.qp.maxIter=6000; o.tolStep=1e-3; o.wFuel=15; o.useCpp=true;
    o.wTilt=0.02;                   % 傾斜正則化 (直立想定ノードのみ. starshipは
                                    % 0.1だと多段求解が数値破綻するため小さめ)
    prob.opt = o;
    prob.passes = struct( ...
      'set',{struct('monoDescent',true,'drBox',[-380 10],'crMax',40,'lamTerm',1e7, ...
                    'sigMax',[10 4 5 26],'maxIter',14,'tolStep',8e-4), ...
             struct('lamTerm',5e7,'sigMax',[10 4 5 34],'wFuel',25,'maxIter',12,'tolStep',6e-4), ...
             struct('lamTerm',1e8,'sigMax',[10 4 5 40],'maxIter',10)}, ...
      'sigma',{[],[],[]});
    prob.planFile = 'landing_vert.mat';
    prob.refSync = 'time';          % 追従参照の同期 (starshipは時刻で十分)
    prob.velFB = 0;                 % 鉛直速度FB (ホバー可能な機体には不要)
    prob.latFreezeAlt = 40;         % 着陸コミット高度 [m]: これ以下で横推力を姿勢レート
                                    % ダンピングに切替 (接地直前のふらつき抑制)
    prob.ctlModeForce = 'inner';    % 制御方式2 (10ms姿勢内ループ+アクチュエータ動特性)
                                    % を既定とする. 方式1は prm.ctlMode='direct'
    prob.errTrig = 60;              % 再計画トリガ [m]: 追従MPCは60m級の偏差まで
                                    % 吸収できるため, 小さすぎる閾値は参照切替の
                                    % 過敏発火で姿勢を乱す (25mではMCS成功2/8 ->
                                    % 60mで8/8, 接地傾斜 max13.4 -> 3.7deg)
    prob.okCrit = struct('horiz',30,'vz',5,'tilt',10);   % MCS成功判定 (ミッション要求)
    prob.cutoffAlt = 0;             % エンジンカットオフ無効 (ホバー可能機には不要)

case 'falcon9'
    cfg = scpk.modelFalcon9(vehOv);
    prob.cfg = cfg;
    prob.cfgPlan = cfg;                          % 計画に推力マージン15%
    prob.cfgPlan.Tmax1 = 0.85*cfg.Tmax1;  prob.cfgPlan.Tmax = 0.85*cfg.Tmax;
    qUp = [1;0;0;0];
    prob.x0 = [2200; 0; -40; -240; 0; 10; qUp; 0;0;0; cfg.m0];
    prob.xT = [cfg.hmin; 0;0; 0;0;0; 0;0;0; 0;0;0];
    prob.phase = [1*ones(1,10), 2*ones(1,8), 3*ones(1,10), 4*ones(1,12)];
    prob.eng   = [0*ones(1,10), 3*ones(1,8), 1*ones(1,10), 1*ones(1,12)];
    N = numel(prob.phase);
    %% 傾斜スケジュールは絞りめ (点火直後のピッチスパイク=傾斜ふらつきの根を抑制)
    tiltN = deg2rad(12)*ones(1,N+1);
    i3=find(prob.phase==3); tiltN(i3(1):end)=deg2rad(8);
    i4=find(prob.phase==4); tiltN(i4(1):N+1)=deg2rad(4);
    prob.tiltN = tiltN;
    prob.sig0 = [2 5 8 5];
    o = scpk.planOptions6();
    o.qBelly=qUp; o.bellyHold=2; o.softGlide=true;
    o.monoDescent=true; o.drBox=[-160 10]; o.crMax=30;
    o.wMaxFlip=deg2rad(6); o.wMaxTight=deg2rad(3);   % 姿勢機動を滑らかに
    o.sigMin=[1 3 4 3]; o.sigMax=[4 8 14 9];
    o.lamTerm=1e6; o.lamGlide=2e5; o.phaseTight=4;
    o.hMargin=3;                    % 高度下限=hmin-3m. 大きくすると計画が脚接地
                                    % 高度(18m)を高速で通過し地下で減速完了する
                                    % 解になる (接地ゲートとの整合が崩れる)
    o.tiltMax=deg2rad(6); o.glideSlope=deg2rad(20);
    o.wFlap=0.5;                    % 舵面正則化: フィンのバンバン動作と姿勢振動を抑制
                                    % (舵角±20°往復→max3.4°, 飛行中傾斜15→3.5°,
                                    %  無風MCS 80→95%. 2.0は強すぎて分散補正まで
                                    %  殺し全ラン失敗する. 0.2-0.5が適正, 実測)
    o.wTilt=0.1;                    % 傾斜正則化: コストが傾斜に無関心だと鉛直降下
                                    % できる場面でも傾く (12.8->3.3deg 実測).
                                    % divert能力は維持 (DR-40mで終端-1.2m).
                                    % 注: 大きすぎるとQPが数値破綻する機体もある
                                    % (starship pass1で0.1がNG, 0.02はOK)
    o.trShrinkRate=0.93; o.trXmin=3; o.trUmin=2; o.trSigMin=0.3;
    o.maxIter=15; o.qp.maxIter=2000; o.tolStep=1e-3; o.wFuel=15; o.useCpp=true;
    prob.opt = o;
    qpTight = o.qp;  qpTight.maxIter = 40000;
    qpTight.tolPri = 1e-6;  qpTight.tolDua = 1e-6;
    prob.passes = struct( ...
      'set',{struct('lamTerm',1e7,'maxIter',8,'tolStep',8e-4), ...
             struct('lamTerm',5e7,'maxIter',10,'tolStep',6e-4, ...
                    'sigMin',[6.5 1.5 2 1.2],'sigMax',[9 5.5 9 5]), ...
             struct('lamTerm',1e8,'maxIter',8,'tolStep',5e-4), ...
             struct('lamTerm',1e8,'maxIter',4,'tolStep',5e-4,'qp',qpTight)}, ...
      'sigma',{[],[7.5 4 4 1.8],[],[]});
    %% pass2: 遅点火の盆地へ誘導. pass4 (磨き): QP許容誤差を1e-6に厳格化.
    %% 通常パスの相対許容誤差1e-3は終端重み1e8の問題では絶対誤差として大きな
    %% 最適性の取り残しを許す (風10m/s時の終端残差 13.5m -> 0.1-1m, 実測).
    %% 反復配分 (SCP 15/8/10/8/4, 継続パスQP 2000) は品質と速度の両立点で
    %% 計画反復配分は、終端精度を維持しつつ求解時間を抑える実測上の折衷点.
    prob.planFile = 'landing_falcon9.mat';
    prob.refSync = 'alt';           % 点火ディスパッチ: 参照を高度で引く
                                    % (ホバースラムのタイミング分散を吸収)
    prob.suicideBurn = true;         % 降下速度・質量・推力効率から停止距離を評価する
                                    % 状態量ベースの点火ディスパッチ
    prob.suicideMargin = 0.995;      % 計画点火点で校正した停止距離の安全倍率
    prob.suicideVtd = 0;             % 停止距離計算上の目標鉛直速度 [m/s]
    prob.suicideNomEff = 0.97;       % 停止距離校正時の公称推力効率
    prob.suicideRefBlend = 0.45;     % 点火時刻補正をMPC参照全体へ反映する割合
    prob.suicideVelBlend = 1.0;      % 同補正を鉛直速度FB参照へ反映する割合
    prob.suicideAdvanceMax = 0;      % 計画点火から許す前倒し量 [s] (0=遅延補正のみ)
    prob.velFB = 0.7;               % 鉛直速度FB [1/s]: v(h)プロファイルへの推力トリム
                                    % (inner方式では強すぎると高所停止後の落下を招く)
    prob.velFBi = 0;                % 積分ゲイン [1/s^2]: 上げると鉛直は締まるが傾斜が
                                    % 悪化するトレードオフ (kI=8で-4.0m/s/13.6deg 実測)
    prob.ctlModeForce = 'inner';    % 誘導が姿勢コマンドを生成し, 姿勢内ループを介して追従
    prob.wnAtt = 1.8;               % 姿勢内ループ帯域 [rad/s]
    prob.ztAtt = 1.2;               % 姿勢内ループ減衰比
    prob.latFreezeAlt = 60;         % 着陸コミット高度 [m]: これ以下で横推力を姿勢レート
                                    % ダンピング専用に切替 (参照終端への最終追い込みが
                                    % 傾斜を蹴るのを防ぐ. 接地傾斜 14->5deg 実測)
    prob.okCrit = struct('horiz',20,'vz',8,'tilt',5);    % MCS成功判定 (ミッション要求.
                                    % ホバー不能機の接地速度はクラッシュコア等での
                                    % 吸収を想定し 8 m/s とする)
    prob.errTrig = 60;              % 再計画トリガ [m]: ホバースラム燃焼中の参照引き直しは
                                    % 姿勢を乱し転倒に至る (25mでMCSに墜落級が発生, 実測).
                                    % 追従で吸収できる偏差では発火させない
    prob.cutoffAlt = 60;            % エンジンカットオフ [m]: T/W_min~1.9 のため接地前に
                                    % 減速し切ると上昇暴走する. 接地高度+60m以下でほぼ
                                    % 停止したら機関停止して落下着地 (実機と同じ運用.
                                    % 墜落級 -52m/s -> 落下接地 ~-10m/s に緩和, 実測)

otherwise
    error('未知の機体: %s (starship / falcon9)', vehicle);
end
prob.vehicle = lower(vehicle);
prob.x0Ref = prob.x0;                            % テンプレートの初期条件 (scpPlanが
                                                 % フェーズ時間の自動伸縮に使用)
prob.windProf = [];                              % 風況プロファイル (閉ループ/MCSへ渡る):
                                                 % struct('h',[m],'wy',[m/s],'wz',[m/s])
                                                 % 例: prob.windProf = loadWindProfile(...
                                                 %       'config/wind_shear_example.json')
prob.track = scpk.track6Options();               % 追従MPCの重み/スケール (編集可)
if strcmp(prob.vehicle,'starship')
    prob.track.wQuat = 2.0;                      % 姿勢追従を強め (接地前のふらつき抑制)
    prob.track.wRate = 1.5;                      % 角速度減衰
end
if strcmp(prob.vehicle,'falcon9')
    prob.track.qp.maxIter = 4000;                % 短時間・高加速の追従QPは反復多め
                                                 % (2500だと収束率53% -> 4000で99%)
    prob.track.fastIter = 600;                   % 固定反復数 (既定300では追従精度が
                                                 % 不足し風時に+9mの残差. 600で~27ms)
    prob.track.wPos = 32;                        % inner方式で着地点への収束を強化
    prob.track.wVel = 0.5;                       % 姿勢要求との競合を避け, 速度FBへ役割分担
    prob.track.wQuat = 2.5;                      % 姿勢追従を強め (傾斜ふらつき抑制)
    prob.track.wRate = 2.0;                      % 角速度減衰
    prob.track.rCtrl = 0.8;                      % 制御を滑らかに
end
end
