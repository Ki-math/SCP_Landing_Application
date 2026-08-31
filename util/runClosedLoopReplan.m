function out = runClosedLoopReplan(prm)
%   PRM (省略可): .thrEff 推力効率 (既定0.97), .errTrig 再計画トリガの
%   追従位置誤差 [m] (既定 25; inf で再計画なし), .dtR 再計画最短間隔 [s]
%RUNCLOSEDLOOPREPLAN  オンライン再計画つき閉ループ (完全なオンラインSCP-MPC).
%
%   構成:
%     - 追従MPC 100 ms (track6Step, C++ソルバ)
%     - 再計画 1 s 周期 (replan6: 現在状態から残り軌道を2反復で引き直し,
%       受け入れ判定つき. 不合格なら旧計画を継続)
%     - プラント RK4 10 ms. 外乱は runClosedLoop6 と同一
%   結果は results/closedloop_replan.mat に保存.
%
%   See also SCPK.REPLAN6, SCPK.TRACK6STEP, RUNCLOSEDLOOP6
here = fileparts(mfilename('fullpath'));  proj = fileparts(here);
addpath(fullfile(proj,'src'), fullfile(proj,'src','cpp'), here);
if nargin < 1, prm = struct(); end
planFile = 'landing_vert.mat';
if isfield(prm,'planFile') && ~isempty(prm.planFile), planFile = prm.planFile; end
S = load(fullfile(proj,'results',planFile));
cfg = S.cfg;  sc = cfg.sc;
if ~isfield(cfg,'atmIsa'), cfg.atmIsa = 0; cfg.hPad = 0; end   % 旧計画ファイル互換
if ~isfield(cfg,'wOn')                                          % 同 (風テーブル)
    cfg.wOn = 0; cfg.wTabH = zeros(1,8); cfg.wTabY = zeros(1,8); cfg.wTabZ = zeros(1,8);
end
tdAlt = cfg.hmin*sc.L;                 % 接地判定高度 (機体依存)
sx = [repmat(sc.L,3,1); repmat(sc.V,3,1); ones(4,1); repmat(1/sc.T,3,1); cfg.m0];

%% --- 計画状態 (tiltN: 保存された opt.tiltMaxNode を使用. 無ければ旧再構成) ---
ph = S.sol.phase;  N = numel(ph);
if isfield(S.opt,'tiltMaxNode') && ~isempty(S.opt.tiltMaxNode)
    tiltN = S.opt.tiltMaxNode;
else
    tiltN = deg2rad(179)*ones(1,N+1);
    i2 = find(ph==2);  tiltN(i2(1):i2(end)+1) = deg2rad(linspace(100,30,numel(i2)+1));
    i3 = find(ph==3);  tiltN(i3(1):i3(end)+1) = deg2rad(linspace(30,10,numel(i3)+1));
    i4 = find(ph==4);  tiltN(i4(1):N+1) = deg2rad(10);
end
plan = struct('sol',S.sol, 'opt',S.opt, 'tiltN',tiltN, 'cfg',cfg, ...
              'xT',[cfg.hmin;0;0;0;0;0;0;0;0;0;0;0]);

%% --- 外乱 (既定は runClosedLoop6 と同一) ---
gp = @(f,d) getFieldDef(prm,f,d);
thrEff  = gp('thrEff', 0.97);
errTrig = gp('errTrig', 25);      % 追従位置誤差がこれを超えたら再計画 [m] (燃焼中)
errTrigC= gp('errTrigCoast', 30); % 同, コースト (点火前) 用の低いトリガ [m].
                                  % コースト中の再計画は燃焼を乱すリスクがなく
                                  % divert が最も安価なため, 感度を高くして
                                  % 着陸点へ向かう軌道の引き直しを積極的に行う
dtR     = gp('dtR', 1.0);
reIters = gp('reIters', 4);       % 再計画のSCP反復数 (divert品質と計算時間の
                                  % トレード. 2ではdivert残差20m級, 4で数m)
engGuard= gp('engGuard', 1.5);    % 過制動ガードの速度しきい値 [m/s] (0で無効)
navJump = gp('navJump', 0);       % t=8s の航法更新 (ダウンレンジ跳び) [m]
windY   = gp('windY', 0.3);       % 横風加速度 [m/s^2] (簡易一定外乱. 旧来互換)
windProf = gp('windProf', []);    % 風況プロファイル struct('h',[m],'wy',[m/s],'wz',[m/s])
                                  % 高度に対する風速 (慣性系: wy=クロスレンジ, wz=ダウンレンジ).
                                  % プラント空力を対気相対速度で評価する. []=無効
windScale = gp('windScale', 1);   % 風プロファイル倍率 (MCS分散用)
if isempty(windProf) && cfg.wOn > 0
    %% 計画が風込みで作られている場合, プラントにも同じ風を既定で与える
    %% (prm.windProf の明示指定が優先)
    windProf = struct('h',cfg.wTabH(:), 'wy',cfg.wTabY(:), 'wz',cfg.wTabZ(:));
end
refSync = gp('refSync', 'time');  % 参照の同期: 'time' 時刻 | 'alt' 高度 (点火ディスパッチ)
suicide = logical(gp('suicideBurn', false)); % 停止距離ベースの初回点火ディスパッチ
suicideMargin = gp('suicideMargin', 1.0);    % 計画点火点に対する停止距離倍率
suicideVtd = gp('suicideVtd', 0);            % 停止距離計算上の目標鉛直速度 [m/s]
suicideNomEff = gp('suicideNomEff', 0.97);   % 計画点火点を校正する公称推力効率
suicideRefBlend = min(max(gp('suicideRefBlend',0.5),0),1); % MPC参照への補正割合
suicideVelBlend = min(max(gp('suicideVelBlend',1.0),0),2); % 鉛直速度参照への補正割合
suicideAdvanceMax = max(gp('suicideAdvanceMax',0),0);       % 計画点火から許す前倒し量 [s]
progFcn = gp('progressFcn', []);  % 進捗コールバック progressFcn(0..1) (GUI用)
ctlMode = gp('ctlMode', 'direct');% 'direct'=方式1 (MPC推力直接) |
                                  % 'inner'=方式2 (10ms姿勢内ループ+アクチュエータ動特性)
wnAtt   = gp('wnAtt', 1.2);       % 姿勢内ループの目標帯域 [rad/s] (方式2)
ztAtt   = gp('ztAtt', 0.9);       % 同 減衰比
latFrz  = gp('latFreezeAlt', 0);  % 着陸コミット高度 [m]: これ以下で横制御をフェード
                                  % (参照終端への最終追い込みが傾斜を蹴る対策. 0=無効)
kInt    = gp('velFBi', 0);        % 鉛直速度FBの積分ゲイン [1/s^2] (推力効率誤差の適応補償)
kVel    = gp('velFB', 0);         % 鉛直速度FBゲイン [1/s]. 高度整合の参照速度
                                  % プロファイル v(h) への高速トリム (ホバースラムの
                                  % 系統的ブレーキ不足を10ms層で補償. refSync='alt'向け)
velTrig = gp('velTrig', inf);     % 再計画トリガの速度誤差 [m/s] (大偏差は非線形再計画で処理)
reAltMin= gp('reAltMin', 220);    % 再計画を許す最低高度 (接地高度からの余裕) [m]
cutAlt  = gp('cutoffAlt', 0);     % エンジンカットオフ判定高度 (接地高度からの余裕) [m].
                                  % ホバー不能機 (T/W_min>1) が接地前に減速し切ると
                                  % 降下再開できず上昇暴走する. この高度以下で鉛直速度が
                                  % cutoffV 以上 (ほぼ停止/上昇) なら機関停止して落下着地
                                  % (実機ホバースラムと同じ運用). 0=無効
cutV    = gp('cutoffV', -0.5);    % カットオフ判定の鉛直速度しきい値 [m/s] (上+)
dr0  = gp('dr0',  [0;0;0]);       % 初期位置オフセット [m] (既定ゼロ. GUI/JSON/MCSで指定)
dvB0 = gp('dvB0', [0;0;0]);       % 初期速度オフセット (機体系) [m/s] (同上)
dr0 = dr0(:);  dvB0 = dvB0(:);
aWind = [0;windY;0]/sc.A;
x0 = S.x0;  x0(1:3) = x0(1:3) + dr0;  x0(4:6) = x0(4:6) + dvB0;

topt = scpk.track6Options();
%% 追従MPCチューニングの上書き (prm.trackOpt.wPos など)
if isfield(prm,'trackOpt') && ~isempty(prm.trackOpt)
    fn = fieldnames(prm.trackOpt);
    for ii = 1:numel(fn), topt.(fn{ii}) = prm.trackOpt.(fn{ii}); end
end
refD = scpk.densify6(plan.sol, cfg, min(0.1, topt.dt/2));   % 参照の高密度化
                                  % (刻みは track.dt に連動: dt/2, 上限0.1s)
vehOv = gp('vehOv', []);          % 機体諸元の変動 (MCS用): プラント側モデルのみ差替
[plantCfg, thrScale] = makePlantCfg(cfg, vehOv);   % 制御器は公称モデルのまま
plant = @(x,u) plantDyn(x,u,plantCfg,thrEff,aWind,thrScale,windProf,windScale);
dtP = gp('dtPlant', topt.dtPlant);  % プラント積分・10ms層 (速度FB/内ループ) の刻み [s]
dtC = gp('dtMpc',   topt.dtCtrl);   % 追従MPCの実行周期 [s] (既定は track6Options.dtCtrl)
dtC = max(dtP, round(dtC/dtP)*dtP);   % プラント刻みの整数倍に丸める
hP = dtP/sc.T;
tEnd = plan.sol.t(end) + 20;

x = x0./sx;  t = 0;  tOff = 0;  z0 = [];  u = zeros(7,1);
%% 方式2 のアクチュエータ状態 (物理単位): スロットル1次遅れ(tauT), TVC 2次系
%% (wnG, ztG), 舵面1次遅れ(tauF). 'direct' では未使用.
inner = strcmpi(ctlMode,'inner');
act.Tm = 0;  act.d = [0;0];  act.dd = [0;0];  act.f = zeros(4,1);
tauT = gp('tauThr', 0.10);        % スロットル1次遅れ時定数 [s]
wnG  = 2*pi*gp('fGim', 6);        % TVC(ジンバル) 2次系の固有周波数 [Hz]
ztG  = gp('ztGim', 0.707);        % 同 減衰比
tauF = gp('tauFlap', 0.20);       % 舵面1次遅れ時定数 [s]
thrLead = gp('thrLead', 0);       % 方式2: スロットル1次遅れのリード補償 (0=なし, 1=標準)
                                  % ホバースラムでは遅れ0.1sが制動精度を落とし
                                  % 「停止高すぎ->落下」の分散を生む. 補償で緩和
actRL = gp('actRateLim', 0);      % 方式2: アクチュエータのスルーレート飽和を有効化
                                  % (機体諸元 tvcRate/flapRate でハード制限.
                                  %  現行の内ループ設計では tvc>=40, flap>=30 deg/s
                                  %  程度が閉ループ成立の目安. 既定は遅れ動特性のみ)
qCmd = x0(7:10)/norm(x0(7:10));  Tc = 0;  uMPC = zeros(7,1);  Tint = 0;  dvF = 0;
TcPrev = 0;
log.t=[]; log.x=[]; log.u=[]; log.qpT=[]; log.st={};
rp.n=0; rp.ok=0; rp.time=[]; rp.t=[];
[hTab,tTab] = altTable(refD, sc);                   %% 高度→参照時刻 の逆引き表
nStep = round(tEnd/dtP);  lastRe = -inf;  navDone = false;  cutDone = false;
engCap = inf;                     %% 過制動ガードの基数ラッチ (engGuard 参照)
sb = initSuicideBurn(refD, cfg, tdAlt, suicideNomEff, suicide, suicideMargin, suicideVtd);
for s = 0:nStep-1
    %% ログ (周期先頭の状態. 生成コード例 gnc_loop.h と同じ規約)
    if mod(s,10)==0, log.t(end+1)=t; log.x(:,end+1)=x.*sx; log.u(:,end+1)=u; end
    if strcmpi(refSync,'alt')
        %% 点火ディスパッチ: 参照を高度で引く. 機体が計画より速い/遅い場合も
        %% 「その高度で取るべき状態・推力」を追うので, ホバースラムの燃焼
        %% タイミング分散を吸収できる (時計同期では原理的に不可能).
        hq = min(max(x(1)*sc.L, hTab(1)), hTab(end));
        tp = interp1(hTab, tTab, hq, 'linear');
    else
        tp = t - tOff;                              %% 現計画の時間軸 (時計同期)
    end
    %% 航法更新イベント: t=8s に自機位置の認識がダウンレンジへ跳ぶ
    if ~navDone && navJump ~= 0 && t >= 8
        x(3) = x(3) - navJump/sc.L;  navDone = true;
    end
    %% --- 再計画 (1 s 周期, 動力飛行中, 高度 > 120 m) ---
    tpRaw = tp;
    if sb.started
        %% 遅延点火時も状態・姿勢参照は現在高度に対応する点を使う.
        %% 前倒し時だけ点火後参照まで進め, 燃焼前のゼロ推力指令を避ける.
        ctrlShift = min(sb.refShift,0) + suicideRefBlend*max(sb.refShift,0);
        tp = min(max(tpRaw - ctrlShift, refD.t(1)), refD.t(end));
        tpEng = min(max(tpRaw - sb.refShift, refD.t(1)), refD.t(end));
    else
        tpEng = tpRaw;
    end
    engNow = interp1(refD.t(1:numel(refD.engSched)), refD.engSched(:), ...
                     min(tpEng,refD.t(end)), 'previous', 'extrap');
    %% --- スーサイドバーン点火ディスパッチ ---
    %% 計画点火時の「残高度 / 最大推力停止距離」を基準にし, 現在の降下速度,
    %% 質量, 推力効率から状態量ベースの点火点を求める. 計画点火が早過ぎる場合は
    %% 点火を待機し, 遅過ぎる場合は前倒しする. 点火時に参照時刻を計画点火点へ
    %% シフトし, 以後のエンジン基数スケジュールを相対的に維持する.
    if sb.enabled && ~sb.started
        qSb = x(7:10)/norm(x(7:10));
        vISb = quat2dcm(qSb.').'*x(4:6);
        vDown = max(-vISb(1)*sc.V, 0);
        hRem = max(x(1)*sc.L - tdAlt, 0);
        mNow = x(14)*plantCfg.m0;
        aBrake = sb.eng*cfg.Tmax1*cfg.Fs*thrEff/mNow - 9.80665;
        dStop = max(vDown^2 - suicideVtd^2, 0)/(2*max(aBrake, eps));
        burnRequired = hRem <= suicideMargin*sb.factor*dStop;
        canStart = burnRequired && tpRaw >= sb.tIgn - suicideAdvanceMax;
        if canStart
            sb.started = true;
            sb.tStart = t;
            sb.hStart = x(1)*sc.L;
            sb.refShift = tpRaw - sb.tIgn;
            sb.advanced = sb.refShift < 0;
            sb.delayed = sb.refShift > 0;
            ctrlShift = min(sb.refShift,0) + suicideRefBlend*max(sb.refShift,0);
            tp = min(max(tpRaw - ctrlShift, refD.t(1)), refD.t(end));
            engNow = sb.eng;
        else
            engNow = 0;
        end
    end
    %% 低高度 (<250 m) では再計画しない: 終端直前の参照切替は追従を乱すだけで
    %% 得るものがない (実測: 水平20 m/傾斜8.5degに劣化). 最終進入は追従に任せる.
    %% トリガ式: 追従位置誤差 > errTrig のときだけ再計画 (小外乱では発火しない.
    %% 周期再計画は小外乱時にかえって精度を落とす — 実測 4.8 m -> 20 m).
    xrNow = interp1(refD.t, refD.xhat.', min(tp,refD.t(end)), 'linear', 'extrap').';
    tpVel = tpRaw;
    if sb.started
        velShift = min(sb.refShift,0) + suicideVelBlend*max(sb.refShift,0);
        tpVel = min(max(tpRaw - velShift, refD.t(1)), refD.t(end));
    end
    xrVel = interp1(refD.t, refD.xhat.', tpVel, 'linear', 'extrap').';
    posErr = norm(x(1:3) - xrNow(1:3))*sc.L;
    velErr = norm(x(4:6) - xrNow(4:6))*sc.V;
    %% --- 過制動ガード (エンジン基数の状態量トリガ前倒し) ---
    %% 参照より降下が遅い (制動しすぎ) のに複数基が最小推力床に張り付くと,
    %% それ以上絞れず過制動が蓄積 -> 高所で停止 -> カットオフ落下になる.
    %% スケジュール上この先で使う少ない基数へ前倒しで落とし, 推力床を下げて
    %% 制動を緩める (実機の状態量トリガ式の基数シーケンスに相当)
    if engGuard > 0 && engNow > 1
        dvSlow = (x(4) - xrNow(4))*sc.V;            % +側 = 降下が参照より遅い
        if dvSlow > engGuard
            nE = numel(refD.engSched);
            iF = find(refD.t(1:nE) >= tp & refD.engSched(:).' > 0);
            if ~isempty(iF)
                engNext = min(refD.engSched(iF));
                %% 前倒しは「残り高度を次基数の最大推力で止まり切れる」場合のみ
                %% (高高度で落とすと制動力不足で回復不能になる)
                mNow  = x(14)*cfg.m0;
                hRem  = max(x(1)*sc.L - tdAlt, 1);
                vNow  = abs(x(4))*sc.V;
                aNet1 = engNext*cfg.Tmax1*cfg.Fs/mNow - 9.81;
                if engNext < engNow && vNow^2/(2*hRem) < 0.8*aNet1
                    engCap = min(engCap, engNext);
                end
            end
        end
    end
    engNow = min(engNow, engCap);                   % ラッチ (戻さない)
    %% 再計画はコースト中 (点火前) も許可する. divert はコーストが最も安価かつ
    %% 安全で, ここを塞ぐと大きな初期偏差が点火まで放置され「着陸点へ向かう
    %% すり鉢」が形成されない (点火後は高度ゲートまで数秒しか窓がない)
    trigNow = errTrig;  if engNow == 0, trigNow = min(errTrig, errTrigC); end
    if t - lastRe >= dtR && x(1)*sc.L > tdAlt+reAltMin && ...
       (posErr > trigNow || velErr > velTrig)
        lastRe = t;
        [plan,okR,dbgR] = scpk.replan6(plan, x.*sx, tp, reIters);
        rp.n = rp.n+1;  rp.ok = rp.ok+okR;  rp.time(end+1) = dbgR.time;  rp.t(end+1) = t;
        if okR
            refD = scpk.densify6(plan.sol, cfg, min(0.1, topt.dt/2));
            [hTab,tTab] = altTable(refD, sc);
            wasStarted = sb.started;
            advancedSb = sb.advanced;
            delayedSb = sb.delayed;
            tStartSb = sb.tStart;  hStartSb = sb.hStart;
            sb = initSuicideBurn(refD, cfg, tdAlt, suicideNomEff, suicide, suicideMargin, suicideVtd);
            if wasStarted
                sb.started = true;  sb.advanced = advancedSb;  sb.delayed = delayedSb;
                sb.tStart = tStartSb;  sb.hStart = hStartSb;
            end
            tOff = t;  z0 = [];                     %% 参照更新, MPCウォームリセット
        end
    end
    %% --- 追従MPC 100 ms ---
    if mod(s, round(dtC/dtP)) == 0
        [uMPC,dbg,z0] = scpk.track6Step(x.*sx, tp, refD, cfg, topt, z0);
        log.qpT(end+1) = dbg.qpTime;  log.st{end+1} = dbg.status;
        qCmd = dbg.qCmd;  Tc = norm(uMPC(1:3))*cfg.Fs;   % 姿勢/推力コマンド (方式2)
        if ~inner, u = uMPC; end
    end
    %% --- 鉛直速度フィードバック (10 ms, 参照 v(h) への推力トリム) ---
    if kVel > 0 && engNow > 0
        dv1 = (xrVel(4) - x(4))*sc.V;               % 機体x速度誤差 [m/s] (参照-実)
        dvF = dvF + dtP/0.3*(dv1 - dvF);            % LPF(0.3s): 推力ジッタ->傾斜結合を切る
        dv1 = dvF;
        mph = x(14)*cfg.m0;                          % 現在質量 [kg]
        Tint = Tint + kInt*mph*dv1/cfg.Fs*dtP;      % 積分トリム (効率誤差の適応補償)
        Tint = min(max(Tint, -0.15*engNow*cfg.Tmax1), 0.15*engNow*cfg.Tmax1);
        T1a = uMPC(1) + kVel*mph*dv1/cfg.Fs + Tint;
        T1a = min(max(T1a, engNow*cfg.Tmin1), engNow*cfg.Tmax1);
    else
        T1a = uMPC(1);
    end
    %% 着陸コミット: 低高度では横制御をフェードし鉛直ブレーキに専念 (姿勢を乱さない)
    if latFrz > 0
        lam = min(max((x(1)*sc.L - tdAlt)/(latFrz - tdAlt), 0), 1);
    else
        lam = 1;
    end
    if ~inner
        u = uMPC;  u(1) = T1a;
        if lam < 1
            %% コミット域: 横推力を「直立への姿勢戻し + レートダンピング」専用へ
            %% (位置追いをやめ, 風でリーンした姿勢を起こして直立で接地する.
            %%  レートダンピングのみでは風下リーン 5-7deg のまま接地する, 実測)
            kdw = 2.0;  kA = 1.5;                   % [1/s] / [1/s^2]
            Lrt = abs(cfg.rT(1))*sc.L;
            wB = x(11:13)/sc.T;
            qn = x(7:10);  sgn = sign(qn(1));  if sgn == 0, sgn = 1; end
            e2 = -2*sgn*qn(3);  e3 = -2*sgn*qn(4);  % 直立への小角誤差 [rad]
            aD2 = kA*e2 - kdw*wB(2);
            aD3 = kA*e3 - kdw*wB(3);
            T2d = -aD3*cfg.Jphys(3,3)/Lrt/cfg.Fs;
            T3d =  aD2*cfg.Jphys(2,2)/Lrt/cfg.Fs;
            u(2) = lam*u(2) + (1-lam)*T2d;
            u(3) = lam*u(3) + (1-lam)*T3d;
        end
        if engNow == 0, u(1:3) = 0; end
    end
    %% --- 姿勢内ループ + アクチュエータ 10 ms (方式2) ---
    if inner
        Tc = norm([T1a; uMPC(2:3)])*cfg.Fs;         % 速度FB込みの推力大きさ
        %% 着陸コミット (lam<1): 姿勢コマンドを直立へフェードし横推力FFを絞る.
        %% 参照終端への最終追い込みが接地間際の姿勢・レートを乱すのを防ぐ
        %% (方式1の姿勢レートダンピング切替と同じ思想. カットオフ落下中の
        %%  傾斜増大 37deg -> 数deg に低減, 実測)
        qC = qCmd;  uFF = uMPC(2:3);
        if lam < 1
            qC = lam*qCmd + (1-lam)*[1;0;0;0];
            nqC = norm(qC);  if nqC > eps, qC = qC/nqC; end
            uFF = lam*uMPC(2:3);
        end
        %% 姿勢誤差 (機体系小角ベクトル): qe = q^-1 (x) qC
        q = x(7:10);
        qe = [ q(1)*qC(1)+q(2)*qC(2)+q(3)*qC(3)+q(4)*qC(4);
               q(1)*qC(2)-q(2)*qC(1)-q(3)*qC(4)+q(4)*qC(3);
               q(1)*qC(3)+q(2)*qC(4)-q(3)*qC(1)-q(4)*qC(2);
               q(1)*qC(4)-q(2)*qC(3)+q(3)*qC(2)-q(4)*qC(1) ];
        eAtt = 2*sign(qe(1))*qe(2:4);                 % [roll;pitch;yaw] 誤差 [rad]
        wB = x(11:13)/sc.T;                           % 角速度 [rad/s]
        aDes = wnAtt^2*eAtt - 2*ztAtt*wnAtt*wB;       % 目標角加速度 [rad/s^2]
        %% 必要横推力: M2=+L*T3, M3=-L*T2 (L=|rT|)
        Lrt = abs(cfg.rT(1))*sc.L;
        Jyy = cfg.Jphys(2,2);  Jzz = cfg.Jphys(3,3);
        T3c =  aDes(2)*Jyy/Lrt;   T2c = -aDes(3)*Jzz/Lrt;
        %% ジンバル角コマンド = MPC横推力のフィードフォワード + PD補正 (小角)
        %% (FFなしのPD単独では フリップの大機動モーメントを再構成できず破綻する)
        dCmd = (uFF*cfg.Fs + [T2c; T3c])/max(Tc,1e3);
        ndCmd = norm(dCmd);
        if ndCmd > cfg.veh.tvcMax
            dCmd = dCmd*(cfg.veh.tvcMax/ndCmd);
        end
        %% アクチュエータ: TVC 2次系, スロットル/舵面 1次遅れ (前進オイラー 10ms)
        %% + スルーレート飽和 (機体諸元 tvcRate / flapRate)
        act.dd = act.dd + dtP*(wnG^2*(dCmd - act.d) - 2*ztG*wnG*act.dd);
        if actRL
            act.dd = max(min(act.dd, plantCfg.veh.tvcRate), -plantCfg.veh.tvcRate);
        end
        act.d  = act.d + dtP*act.dd;
        ndAct = norm(act.d);
        if ndAct > plantCfg.veh.tvcMax
            act.d = act.d*(plantCfg.veh.tvcMax/ndAct);
            radialRate = dot(act.d,act.dd)/dot(act.d,act.d);
            if radialRate > 0
                act.dd = act.dd - radialRate*act.d;
            end
        end
        %% スロットルコマンド (thrLead>0 で1次遅れのリード補償)
        if thrLead > 0
            Tcm = Tc + thrLead*tauT*(Tc - TcPrev)/dtP;
            Tcm = min(max(Tcm, 0), engNow*cfg.Tmax1*cfg.Fs);
        else
            Tcm = Tc;
        end
        TcPrev = Tc;
        act.Tm = act.Tm + dtP*(Tcm - act.Tm)/tauT;
        df = (uMPC(4:7) - act.f)/tauF;
        if actRL
            df = max(min(df, plantCfg.veh.flapRate), -plantCfg.veh.flapRate);
        end
        act.f  = act.f + dtP*df;
        u = [act.Tm*[1; act.d(1); act.d(2)]/cfg.Fs; act.f];
        if Tc < 1e3, u(1:3) = 0; end                  % エンジン停止中
        if sb.enabled && ~sb.started
            act.Tm = 0;
            u(1:3) = 0;                               % 状態量点火点まで待機
        end
    end
    %% --- エンジンカットオフ (ホバースラム: 低高度で停止したら落下着地) ---
    if cutAlt > 0 && ~cutDone && engNow > 0 && x(1)*sc.L < tdAlt + cutAlt
        qn = x(7:10)/norm(x(7:10));
        vI1 = (quat2dcm(qn.').'*x(4:6));           % 慣性系速度 (無次元)
        if vI1(1)*sc.V > cutV
            cutDone = true;                         % ラッチ (以降は機関停止)
        end
    end
    if cutDone, u(1:3) = 0; end
    %% --- プラント 10 ms ---
    k1=plant(x,u); k2=plant(x+hP/2*k1,u); k3=plant(x+hP/2*k2,u); k4=plant(x+hP*k3,u);
    x = x + hP/6*(k1+2*k2+2*k3+k4);
    x(7:10) = x(7:10)/norm(x(7:10));
    t = t + dtP;
    if ~isempty(progFcn) && mod(s,200)==0
        progFcn(min(t/(plan.sol.t(end)+5), 0.98));
    end
    if x(1)*sc.L <= tdAlt, break; end
end
if ~isempty(progFcn), progFcn(1); end

%% --- 集計 ---
xE = x.*sx;  q = xE(7:10)/norm(xE(7:10));
rdI = quat2dcm(q.').'*xE(4:6);
tilt = acosd(max(-1,min(1,1-2*(q(3)^2+q(4)^2))));
fprintf('\n=== 再計画つき閉ループ ===\n');
fprintf('接地 t=%.1fs 水平%.2fm 鉛直v%+.2fm/s |v|%.2f 傾斜%.2fdeg\n', ...
    t, hypot(xE(2),xE(3)), rdI(1), norm(rdI), tilt);
if isfield(topt,'fastQP') && topt.fastQP
    fixedIter = 300;
    if isfield(topt,'fastIter'), fixedIter = topt.fastIter; end
    okStatus = strcmp(log.st,'converged') | strcmp(log.st,'maxIter');
    fprintf('MPC %d回: QP平均%.1fms 固定%d反復 異常率%.0f%%\n', numel(log.qpT), ...
        mean(log.qpT)*1e3, fixedIter, 100*mean(~okStatus));
else
    fprintf('MPC %d回: QP平均%.1fms 収束率%.0f%%\n', numel(log.qpT), ...
        mean(log.qpT)*1e3, 100*mean(strcmp(log.st,'converged')));
end
fprintf('再計画 %d回 (受入 %d): 1回あたり 平均%.0fms / 最大%.0fms\n', ...
    rp.n, rp.ok, mean(rp.time)*1e3, max(rp.time)*1e3);

prmUsed = struct('thrEff',thrEff,'errTrig',errTrig,'dtR',dtR,'navJump',navJump, ...
                 'windY',windY,'windProf',windProf,'windScale',windScale, ...
                 'ctlMode',ctlMode,'refSync',refSync,'suicideBurn',suicide, ...
                 'suicideMargin',suicideMargin,'suicideVtd',suicideVtd, ...
                 'suicideNomEff',suicideNomEff,'suicideRefBlend',suicideRefBlend, ...
                 'suicideVelBlend',suicideVelBlend,'suicideAdvanceMax',suicideAdvanceMax);
out = struct('log',log,'rp',rp,'xEnd',xE,'tEnd',t,'plan',plan,'prm',prmUsed, ...
             'suicideBurn',sb);
fprintf('条件: thrEff=%.2f windY=%.1f navJump=%.0fm errTrig=%s\n', ...
    thrEff, windY, navJump, num2str(errTrig));
if gp('noSave',0), return; end          %% MCS並列時のファイル衝突回避
save(fullfile(proj,'results','closedloop_replan.mat'),'-struct','out');
fprintf('保存: results/closedloop_replan.mat\n');
end


function sb = initSuicideBurn(refD, cfg, tdAlt, thrEff, enabled, margin, vTd)
%INITSUICIDEBURN  計画点火点から停止距離ディスパッチの基準を作る.
sb = struct('enabled',false,'started',false,'advanced',false,'delayed',false, ...
            'refShift',0,'tIgn',0,'hIgn',nan,'eng',0,'factor',1,'margin',margin, ...
            'vTd',vTd,'tStart',nan,'hStart',nan);
if ~enabled || isempty(refD.engSched), return; end
iIgn = find(refD.engSched > 0, 1, 'first');
if isempty(iIgn), return; end
iState = min(iIgn, size(refD.xhat,2));
xr = refD.xhat(:,iState);
qr = xr(7:10)/norm(xr(7:10));
vIr = quat2dcm(qr.').'*xr(4:6);
vDown = max(-vIr(1)*cfg.sc.V, 0);
hRem = max(xr(1)*cfg.sc.L - tdAlt, 0);
mRef = xr(14)*cfg.m0;
eng = refD.engSched(iIgn);
aBrake = eng*cfg.Tmax1*cfg.Fs*thrEff/mRef - 9.80665;
dStop = max(vDown^2 - vTd^2, 0)/(2*max(aBrake, eps));
if hRem <= 0 || dStop <= eps || aBrake <= 0, return; end
sb.enabled = true;
sb.tIgn = refD.t(iIgn);
sb.hIgn = xr(1)*cfg.sc.L;
sb.eng = eng;
sb.factor = hRem/dStop;
end


function v = getFieldDef(s,f,d)
if isfield(s,f), v = s.(f); else, v = d; end
end


function [hTab,tTab] = altTable(refD, sc)
%ALTTABLE  高度 -> 参照時刻 の逆引き表 (refSync='alt' 用).
%   高度は単調降下前提 (計画に monoDescent). 数値的な平坦部は微小勾配で
%   一意化して interp1 可能にする.
alt = refD.xhat(1,:)*sc.L;
a = cummin(alt);                            % 単調非増加へ
a = a - (0:numel(a)-1)*1e-9;                % 厳密単調へ (一意化)
hTab = fliplr(a);  tTab = fliplr(refD.t);   % interp1 は増加軸が必要
end


function [pc, thrScale] = makePlantCfg(cfg, vehOv)
%MAKEPLANTCFG  計画cfgから諸元を復元し, 変動 vehOv を上書きしてプラント用cfgを再構築.
%   制御器は公称 cfg のまま動くため, ここで作る差分がモデル誤差ロバスト性の評価になる.
%   thrScale: 推力指令の単位換算 (指令は公称Fs基準の無次元. 物理推力を保存する)
if isempty(vehOv) || isempty(fieldnames(vehOv)), pc = cfg; thrScale = 1; return; end
sc = cfg.sc;
ov = cfg.veh;                                   % 一次諸元 (計画時の値)
ov.Ixx = cfg.Jphys(1,1);  ov.Iyy = cfg.Jphys(2,2);  ov.Izz = cfg.Jphys(3,3);
ov.rTx = cfg.rT(1)*sc.L;
ov.rho = cfg.rho;  ov.aeroScale = cfg.aeroScale;  ov.LoverD = cfg.LoverD;
ov.atmIsa = cfg.atmIsa;  ov.hPad = cfg.hPad;
Sx = pi*cfg.veh.R^2;  Sy = cfg.veh.Lb*2*cfg.veh.R;
ov.CdAx   = cfg.cx*cfg.Fs/(cfg.aeroScale*0.5*cfg.rho*Sx*sc.V^2);
ov.CdSide = cfg.cy*cfg.Fs/(cfg.aeroScale*0.5*cfg.rho*Sy*sc.V^2);
ov.VrefSurf = sqrt(cfg.V2ref)*sc.V;
ov.hmin_m = cfg.hmin*sc.L;  ov.wMaxDeg = rad2deg(cfg.wMax/sc.T);
ov.kFlapDrag = cfg.cFlapDrag*sc.A/max(cfg.veh.flapTrim^2, eps);
sg = 1;  fn = fieldnames(vehOv);
for ii = 1:numel(fn)
    if strcmp(fn{ii},'surfGain'), sg = vehOv.surfGain;   % 舵面効きは計画値に乗算で扱う
    else, ov.(fn{ii}) = vehOv.(fn{ii}); end
end
if cfg.surfMode == 2, pc = scpk.modelFalcon9(ov); else, pc = scpk.model6(ov); end
pc.Bflap = sg*cfg.Bflap;                        % 計画時の効き行列を基準に変動
thrScale = cfg.Fs/pc.Fs;
end


function f = plantDyn(x,u,cfg,thrEff,aWind,thrScale,wp,wScale)
%PLANTDYN  プラント側の状態微分. 推力効率/単位換算 + 風の注入.
%   風は2系統:
%     wp (windProf): 高度依存の風速プロファイル [m/s]. 空力を対気相対速度で
%                    評価する物理的なモデル (dynamics6 の wB 経由)
%     aWind (windY): 一定の加速度外乱 [m/s^2] (旧来互換の簡易モデル)
up = u;  up(1:3) = thrEff*thrScale*u(1:3);
q = x(7:10);  q0=q(1); q1=q(2); q2=q(3); q3=q(4);
R = [1-2*(q2*q2+q3*q3),   2*(q1*q2+q0*q3),   2*(q1*q3-q0*q2);
       2*(q1*q2-q0*q3), 1-2*(q1*q1+q3*q3),   2*(q2*q3+q0*q1);
       2*(q1*q3+q0*q2),   2*(q2*q3-q0*q1), 1-2*(q1*q1+q2*q2)];
wB = zeros(3,1);
if ~isempty(wp)
    h  = x(1)*cfg.sc.L;                              % パッド基準高度 [m]
    hq = min(max(h, wp.h(1)), wp.h(end));            % 端はクランプ
    wI = wScale*[0; interp1(wp.h, wp.wy, hq); interp1(wp.h, wp.wz, hq)]/cfg.sc.V;
    wB = R*wI;                                       % 機体系へ (無次元)
end
f = scpk.dynamics6(x, up, cfg, wB);
f(4:6) = f(4:6) + R*aWind;
end
