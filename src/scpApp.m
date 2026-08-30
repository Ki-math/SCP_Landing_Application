function scpApp()
%SCPAPP  再利用ロケット着陸解析 GUI (統合表示版).
%
%   SCPAPP で起動. 左: 設定 (機体諸元・初期条件・重み・制御・外乱・MCS),
%   右: タブ表示 (アニメーション / プロット / MCS) — 別ウィンドウを開かない.
%   ボタン: [計画] [閉ループ] [再生] [MCS] [組み込みzip]
%
%   See also SCPPROBLEM, SCPPLAN, SCPCLOSEDLOOP, RUNMCS_SCP, SCPCODEGENZIP
src = fileparts(mfilename('fullpath'));  proj = fileparts(src);
addpath(src, fullfile(src,'cpp'), fullfile(proj,'util'), ...
        fullfile(proj,'util','legacy'), fullfile(proj,'config'));

fig = uifigure('Name','SCP着陸解析ツール','Position',[40 40 1380 800]);
gm = uigridlayout(fig,[1 2],'ColumnWidth',{460,'1x'},'Padding',[8 8 8 8]);

%% ================= 左: 設定列 =================
lp = uipanel(gm);
g = uigridlayout(lp,[4 1],'RowHeight',{'fit','fit','1x',110}, ...
                 'Padding',[6 6 6 6],'RowSpacing',5);

%% ---- 実行ボタン (最上段: 常に見える位置) ----
p6 = uipanel(g,'Title','実行');
g6 = uigridlayout(p6,[1 5],'ColumnSpacing',5,'Padding',[6 4 6 4]);
uibutton(g6,'Text','計画','ButtonPushedFcn',@(s,e) doPlan());
uibutton(g6,'Text','閉ループ','ButtonPushedFcn',@(s,e) doCL());
uibutton(g6,'Text','再生','ButtonPushedFcn',@(s,e) doAnim());
uibutton(g6,'Text','MCS','ButtonPushedFcn',@(s,e) doMCS());
uibutton(g6,'Text','コード生成','ButtonPushedFcn',@(s,e) doZip());

%% ---- 設定ファイル (JSON) ----
p8 = uipanel(g,'Title','設定ファイル (JSON)');
g8 = uigridlayout(p8,[1 4],'ColumnWidth',{'fit','fit','fit','1x'},'ColumnSpacing',5,'Padding',[6 4 6 4]);
uibutton(g8,'Text','読込','ButtonPushedFcn',@(s,e) doLoadJson());
uibutton(g8,'Text','保存','ButtonPushedFcn',@(s,e) doSaveJson());
uibutton(g8,'Text','スクリプト生成','Tooltip','現在のGUI設定で解析を再現するMATLABスクリプト (.m) を書き出す', ...
    'ButtonPushedFcn',@(s,e) doGenScript());
W.jsonLbl = uilabel(g8,'Text','(未読込. 例: config/settings_starship.json)');

%% ---- 設定タブ (全項目をスクロールなしで見えるように) ----
tgL = uitabgroup(g);
tabB = uitab(tgL,'Title','機体');
gtB = uigridlayout(tabB,[2 1],'RowHeight',{'fit','fit'},'Padding',[4 4 4 4],'RowSpacing',5);
tabD = uitab(tgL,'Title','詳細諸元');
gtD = uigridlayout(tabD,[1 1],'RowHeight',{'fit'},'Padding',[4 4 4 4],'RowSpacing',5);
tabE = uitab(tgL,'Title','環境');
gtE = uigridlayout(tabE,[2 1],'RowHeight',{'fit','1x'},'Padding',[4 4 4 4],'RowSpacing',5);
tabT = uitab(tgL,'Title','調整');
gtT = uigridlayout(tabT,[3 1],'RowHeight',{'fit','fit','fit'},'Padding',[4 4 4 4],'RowSpacing',5);
tabC = uitab(tgL,'Title','制御');
gtC = uigridlayout(tabC,[3 1],'RowHeight',{'fit','fit','fit'},'Padding',[4 4 4 4],'RowSpacing',5);
tabM = uitab(tgL,'Title','MCS');
gtM = uigridlayout(tabM,[3 1],'RowHeight',{'fit','fit','1x'},'Padding',[4 4 4 4],'RowSpacing',5);
tabP = uitab(tgL,'Title','再生');
gtP = uigridlayout(tabP,[1 1],'RowHeight',{'fit'},'Padding',[4 4 4 4],'RowSpacing',5);

%% ---- 機体 / 初期条件 ----
p1 = uipanel(gtB,'Title','機体 / 初期条件');
g1 = uigridlayout(p1,[3 4],'ColumnWidth',{'fit','1x','fit','1x'},'RowSpacing',3,'Padding',[6 4 6 4]);
uilabel(g1,'Text','機体');
W.veh = uidropdown(g1,'Items',{'starship','falcon9'},'Value','starship', ...
    'ValueChangedFcn',@(s,e) setDefaults());
uilabel(g1,'Text','高度 [m]');        W.alt = uieditfield(g1,'numeric');
uilabel(g1,'Text','ダウンレンジ [m]'); W.dr  = uieditfield(g1,'numeric');
uilabel(g1,'Text','クロス [m]');       W.cr  = uieditfield(g1,'numeric');
uilabel(g1,'Text','降下速度 [m/s]');   W.vd  = uieditfield(g1,'numeric');
uilabel(g1,'Text','水平速度 [m/s]');   W.vh  = uieditfield(g1,'numeric');

%% ---- 機体諸元 ----
p1b = uipanel(gtB,'Title','機体諸元 (一次パラメータ, 派生量は自動再計算)');
g1b = uigridlayout(p1b,[5 4],'ColumnWidth',{'fit','1x','fit','1x'},'RowSpacing',3,'Padding',[6 4 6 4]);
uilabel(g1b,'Text','乾燥質量 [t]');    W.mDry = uieditfield(g1b,'numeric');
uilabel(g1b,'Text','推進薬 [t]');      W.mPro = uieditfield(g1b,'numeric');
uilabel(g1b,'Text','全長 [m]');        W.Lb   = uieditfield(g1b,'numeric');
uilabel(g1b,'Text','半径 [m]');        W.Rb   = uieditfield(g1b,'numeric');
uilabel(g1b,'Text','エンジン数');      W.nE   = uieditfield(g1b,'numeric');
uilabel(g1b,'Text','推力/基 [kN]');    W.Te   = uieditfield(g1b,'numeric');
uilabel(g1b,'Text','Isp [s]');         W.isp  = uieditfield(g1b,'numeric');
uilabel(g1b,'Text','最低スロットル');  W.thrM = uieditfield(g1b,'numeric');
uilabel(g1b,'Text','ジンバル最大 [deg]'); W.tvc = uieditfield(g1b,'numeric');
uilabel(g1b,'Text','');  uilabel(g1b,'Text','');

%% ---- 詳細諸元 (従来自動計算だった派生量. 機体リセットで自動値を表示) ----
p1c = uipanel(gtD,'Title','派生量 (すべてユーザー指定可. 機体リセットで自動計算値に戻る)');
g1c = uigridlayout(p1c,[7 4],'ColumnWidth',{'fit','1x','fit','1x'},'RowSpacing',3,'Padding',[6 4 6 4]);
uilabel(g1c,'Text','慣性 Ixx [t·m²]');    W.Ixx  = uieditfield(g1c,'numeric');
uilabel(g1c,'Text','慣性 Iyy [t·m²]');    W.Iyy  = uieditfield(g1c,'numeric');
uilabel(g1c,'Text','慣性 Izz [t·m²]');    W.Izz  = uieditfield(g1c,'numeric');
uilabel(g1c,'Text','推力作用点 x [m]');   W.rTx  = uieditfield(g1c,'numeric');
uilabel(g1c,'Text','大気密度 [kg/m³]');   W.rhoA = uieditfield(g1c,'numeric');
uilabel(g1c,'Text','抗力係数 軸方向');    W.cdA  = uieditfield(g1c,'numeric');
uilabel(g1c,'Text','抗力係数 横方向');    W.cdS  = uieditfield(g1c,'numeric');
uilabel(g1c,'Text','空力スケール');       W.aSc  = uieditfield(g1c,'numeric');
uilabel(g1c,'Text','揚抗比 L/D');         W.lod  = uieditfield(g1c,'numeric');
uilabel(g1c,'Text','舵面同定速度 [m/s]'); W.vSrf = uieditfield(g1c,'numeric');
uilabel(g1c,'Text','舵面効きゲイン');     W.sGn  = uieditfield(g1c,'numeric');
uilabel(g1c,'Text','舵面抗力係数');       W.kFd  = uieditfield(g1c,'numeric');
uilabel(g1c,'Text','接地CG高 [m]');       W.hMn  = uieditfield(g1c,'numeric');
uilabel(g1c,'Text','角速度上限 [deg/s]'); W.wMx  = uieditfield(g1c,'numeric');

%% ---- 環境: 大気 ----
pE1 = uipanel(gtE,'Title','大気');
gE1 = uigridlayout(pE1,[1 4],'ColumnWidth',{'fit','1x','fit','1x'},'RowSpacing',3,'Padding',[6 4 6 4]);
uilabel(gE1,'Text','大気モデル');
W.atm = uidropdown(gE1,'Items',{'ISA標準大気','一定密度'},'Value','ISA標準大気');
uilabel(gE1,'Text','パッド標高 [m]');  W.hPad = uieditfield(gE1,'numeric','Value',0);
W.windTune = uicheckbox(gE1,'Text','強風チューニング','Value',false, ...
    'Tooltip',['姿勢レート・傾斜スケジュール・コースト姿勢の制約を緩め, 追従の姿勢重みを' ...
    '強化する実測レシピ (scpWindTune). クロス風10m/s級で水平誤差45m->4.5mに改善. ' ...
    '風プロファイル設定時に推奨']);

%% ---- 環境: 風況プロファイル (分布プロットは右の「風況」タブに表示) ----
pE2 = uipanel(gtE,'Title','風況プロファイル (高度 vs 風速. 2行未満 = 無風)');
gE2 = uigridlayout(pE2,[2 1],'RowHeight',{'fit','1x'},'RowSpacing',3,'Padding',[6 4 6 4]);
gE2b = uigridlayout(gE2,[1 4],'ColumnSpacing',4,'Padding',[0 0 0 0]);
uibutton(gE2b,'Text','行追加','ButtonPushedFcn',@(s,e) windAddRow());
uibutton(gE2b,'Text','行削除','ButtonPushedFcn',@(s,e) windDelRow());
uibutton(gE2b,'Text','JSON読込','ButtonPushedFcn',@(s,e) windLoadJson());
uibutton(gE2b,'Text','クリア','ButtonPushedFcn',@(s,e) windClear());
W.wndT = uitable(gE2,'Data',zeros(0,3), ...
    'ColumnName',{'高度 [m]','クロス風 [m/s]','DR風 [m/s]'}, ...
    'ColumnEditable',true(1,3),'CellEditCallback',@(s,e) updateWindPlot(true));

%% ---- 計画 ----
p2 = uipanel(gtT,'Title','計画 (重み/スケーリング)');
g2 = uigridlayout(p2,[3 4],'ColumnWidth',{'fit','1x','fit','1x'},'RowSpacing',3,'Padding',[6 4 6 4]);
uilabel(g2,'Text','log10(終端重み)'); W.lamT = uieditfield(g2,'numeric','Value',8);
uilabel(g2,'Text','燃料重み');        W.wF   = uieditfield(g2,'numeric','Value',25);
uilabel(g2,'Text','位置許容 [m]');    W.tolP = uieditfield(g2,'numeric','Value',5);
uilabel(g2,'Text','速度許容 [m/s]');  W.tolV = uieditfield(g2,'numeric','Value',0.5);
uilabel(g2,'Text','ノード倍率');      W.ndF  = uieditfield(g2,'numeric','Value',1, ...
    'Tooltip',['計画のノード分割数の倍率 (テンプレート: starship 50 / falcon9 40ノード). ' ...
    '増やすと離散化が細かくなるがQP規模ほぼ比例で計画が遅くなる (上限N=200). ' ...
    'フェーズ構成・点火・傾斜スケジュールは整合再構成される (scpSetNodes)']);

%% ---- 追従・制御 ----
p3 = uipanel(gtT,'Title','追従MPC / 制御');
g3 = uigridlayout(p3,[3 4],'ColumnWidth',{'fit','1x','fit','1x'},'RowSpacing',3,'Padding',[6 4 6 4]);
uilabel(g3,'Text','制御方式');
W.ctl = uidropdown(g3,'Items',{'方式1: MPC直接','方式2: 内ループ+アクチュエータ'}, ...
                   'Value','方式2: 内ループ+アクチュエータ');
uilabel(g3,'Text','位置重み');       W.wPos = uieditfield(g3,'numeric','Value',8);
uilabel(g3,'Text','速度重み');       W.wVel = uieditfield(g3,'numeric','Value',2);
uilabel(g3,'Text','姿勢重み');       W.wQt  = uieditfield(g3,'numeric','Value',2, ...
    'Tooltip','追従MPCの姿勢誤差重み wQuat. 上げると姿勢のブレ (接地前のふらつき) を抑える');
uilabel(g3,'Text','角速度重み');     W.wRt  = uieditfield(g3,'numeric','Value',1.5, ...
    'Tooltip','追従MPCの角速度重み wRate. 上げると姿勢レートを減衰しふらつきを抑える');
uilabel(g3,'Text','ホライズン節点'); W.H    = uieditfield(g3,'numeric','Value',25);

%% ---- 外乱 ----
p4 = uipanel(gtT,'Title','外乱 / 再計画');
g4 = uigridlayout(p4,[5 4],'ColumnWidth',{'fit','1x','fit','1x'},'RowSpacing',3,'Padding',[6 4 6 4]);
uilabel(g4,'Text','推力効率');         W.thr = uieditfield(g4,'numeric','Value',0.97);
uilabel(g4,'Text','横風 [m/s^2]');     W.wnd = uieditfield(g4,'numeric','Value',0.3);
uilabel(g4,'Text','航法ジャンプ [m]'); W.nav = uieditfield(g4,'numeric','Value',0);
uilabel(g4,'Text','再計画トリガ [m]'); W.eTr = uieditfield(g4,'numeric','Value',40);
uilabel(g4,'Text','初期位置offset 高度 [m]');   W.dr0a = uieditfield(g4,'numeric','Value',0);
uilabel(g4,'Text','同 クロス [m]');             W.dr0c = uieditfield(g4,'numeric','Value',0);
uilabel(g4,'Text','同 ダウンレンジ [m]');       W.dr0d = uieditfield(g4,'numeric','Value',0);
uilabel(g4,'Text','初期速度offset x (機体) [m/s]'); W.dv0x = uieditfield(g4,'numeric','Value',0);
uilabel(g4,'Text','同 y [m/s]');                W.dv0y = uieditfield(g4,'numeric','Value',0);
uilabel(g4,'Text','同 z [m/s]');                W.dv0z = uieditfield(g4,'numeric','Value',0);

%% ---- 制御: 誘導 (機体切替でテンプレート値にリセット) ----
pC1 = uipanel(gtC,'Title','誘導 (ホバースラム系. 機体テンプレート既定)');
gC1 = uigridlayout(pC1,[3 4],'ColumnWidth',{'fit','1x','fit','1x'},'RowSpacing',3,'Padding',[6 4 6 4]);
uilabel(gC1,'Text','参照同期');
W.refS = uidropdown(gC1,'Items',{'時刻同期 (time)','高度同期 (alt)'}, ...
    'Tooltip','alt=点火ディスパッチ: 高度で参照を引きホバースラムのタイミング分散を吸収');
uilabel(gC1,'Text','鉛直速度FB [1/s]');   W.vFB  = uieditfield(gC1,'numeric', ...
    'Tooltip','参照v(h)への推力トリム比例ゲイン velFB (ホバー不能機のブレーキ補償)');
uilabel(gC1,'Text','同 積分 [1/s²]');     W.vFBi = uieditfield(gC1,'numeric', ...
    'Tooltip','velFBi. 大きくすると鉛直は締まるが傾斜が悪化 (発散注意)');
uilabel(gC1,'Text','着陸コミット高度 [m]'); W.latF = uieditfield(gC1,'numeric', ...
    'Tooltip','latFreezeAlt. これ以下で横推力を姿勢レートダンピング専用に切替 (0=無効)');
uilabel(gC1,'Text','カットオフ高度 [m]');  W.cutA = uieditfield(gC1,'numeric', ...
    'Tooltip','cutoffAlt. 接地高度+これ以下でほぼ停止したら機関停止し落下着地 (0=無効)');
uilabel(gC1,'Text','同 速度閾値 [m/s]');   W.cutV = uieditfield(gC1,'numeric','Value',-0.5, ...
    'Tooltip','cutoffV. 鉛直速度がこれ以上 (ほぼ停止/上昇) で発動');

%% ---- 制御: 内ループ・アクチュエータ (方式2) ----
pC2 = uipanel(gtC,'Title','姿勢内ループ / アクチュエータ (方式2で使用)');
gC2 = uigridlayout(pC2,[4 4],'ColumnWidth',{'fit','1x','fit','1x'},'RowSpacing',3,'Padding',[6 4 6 4]);
uilabel(gC2,'Text','姿勢帯域 [rad/s]');    W.wnA  = uieditfield(gC2,'numeric','Value',1.2,'Tooltip','wnAtt');
uilabel(gC2,'Text','同 減衰比');           W.ztA  = uieditfield(gC2,'numeric','Value',0.9,'Tooltip','ztAtt');
uilabel(gC2,'Text','スロットル遅れ [s]');  W.tauT = uieditfield(gC2,'numeric','Value',0.10,'Tooltip','tauThr (1次遅れ)');
uilabel(gC2,'Text','TVC周波数 [Hz]');      W.fG   = uieditfield(gC2,'numeric','Value',6,'Tooltip','fGim (2次系)');
uilabel(gC2,'Text','TVC減衰比');           W.ztG  = uieditfield(gC2,'numeric','Value',0.707,'Tooltip','ztGim');
uilabel(gC2,'Text','舵面遅れ [s]');        W.tauF = uieditfield(gC2,'numeric','Value',0.20,'Tooltip','tauFlap (1次遅れ)');
uilabel(gC2,'Text','スロットルリード補償'); W.tLd = uieditfield(gC2,'numeric','Value',0, ...
    'Tooltip',['thrLead. スロットル1次遅れのリード補償 (0=なし, 0.5-1=補償). ' ...
    'ホバースラム機の方式2で制動精度が改善 (MCS成功率 35->50% 実測)']);
W.aRL = uicheckbox(gC2,'Text','スルーレート飽和','Value',false, ...
    'Tooltip',['actRateLim. 機体諸元 tvcRate/flapRate でハード制限. ' ...
    '既定の実機値 (20/15deg/s) のまま有効化すると内ループが発散する点に注意 (ガイド§6)']);
uilabel(gC2,'Text','');

%% ---- 制御: 実行周期 ----
pC3 = uipanel(gtC,'Title','実行周期');
gC3 = uigridlayout(pC3,[1 4],'ColumnWidth',{'fit','1x','fit','1x'},'RowSpacing',3,'Padding',[6 4 6 4]);
uilabel(gC3,'Text','MPC周期 [s]');        W.dtC = uieditfield(gC3,'numeric','Value',0.10, ...
    'Tooltip','dtMpc. 追従MPCの実行周期 (プラント刻みの整数倍に丸め)');
uilabel(gC3,'Text','プラント刻み [s]');    W.dtP = uieditfield(gC3,'numeric','Value',0.01, ...
    'Tooltip','dtPlant. プラント積分と10ms層 (速度FB/内ループ/アクチュエータ) の刻み');

%% ---- MCS ----
p5 = uipanel(gtM,'Title','モンテカルロ');
g5 = uigridlayout(p5,[2 4],'ColumnWidth',{'fit','1x','fit','1x'},'RowSpacing',3,'Padding',[6 4 6 4]);
uilabel(g5,'Text','標本数');  W.mcsN = uieditfield(g5,'numeric','Value',8);
W.mcsPar = uicheckbox(g5,'Text','並列');  uilabel(g5,'Text','');
uilabel(g5,'Text','変動定義');
W.mcsSrc = uidropdown(g5,'Items',{'ファイル','GUI表'},'Value','ファイル');
uilabel(g5,'Text','ファイル');
ddm = dir(fullfile(proj,'config','dispersions_*.m'));
ddj = dir(fullfile(proj,'config','dispersions_*.json'));
items = [cellfun(@(n) n(1:end-2), {ddm.name}, 'Uni',0), {ddj.name}];
W.mcsF = uidropdown(g5,'Items',items);

%% ---- MCS: 成功判定 (okCrit. 機体切替でテンプレート値にリセット) ----
p5c = uipanel(gtM,'Title','成功判定 (3条件すべて満たせば成功. サマリ表の色分けにも使用)');
g5d = uigridlayout(p5c,[1 6],'ColumnWidth',{'fit','1x','fit','1x','fit','1x'},'RowSpacing',3,'Padding',[6 4 6 4]);
uilabel(g5d,'Text','水平誤差 [m] ≤');   W.okH = uieditfield(g5d,'numeric','Value',30, ...
    'Tooltip','okCrit.horiz: 接地位置のパッドからの距離');
uilabel(g5d,'Text','接地速度 [m/s] ≤'); W.okV = uieditfield(g5d,'numeric','Value',5, ...
    'Tooltip','okCrit.vz: 接地時の速度ベクトルの大きさ |v| (鉛直・水平の合成)');
uilabel(g5d,'Text','傾斜 [deg] ≤');     W.okT = uieditfield(g5d,'numeric','Value',10, ...
    'Tooltip','okCrit.tilt: 接地時の機体傾斜角');

%% ---- MCS: 変動定義の表編集 (ソース='GUI表' のとき使用) ----
p5b = uipanel(gtM,'Title','変動定義 (GUI表. normal系: p1=平均, p2=1σ. 変動なしの行=σ0/上下限同値は実行時に無視)');
g5b = uigridlayout(p5b,[2 1],'RowHeight',{'fit','1x'},'RowSpacing',3,'Padding',[6 4 6 4]);
g5c = uigridlayout(g5b,[1 4],'ColumnSpacing',4,'Padding',[0 0 0 0]);
uibutton(g5c,'Text','一覧リセット','Tooltip','全変動パラメータの一覧に戻す (機体既定の変動を反映)', ...
    'ButtonPushedFcn',@(s,e) dspReset());
uibutton(g5c,'Text','行追加','Tooltip','任意の閉ループprm項目 (errTrig等) を追加', ...
    'ButtonPushedFcn',@(s,e) dspAddRow());
uibutton(g5c,'Text','行削除','ButtonPushedFcn',@(s,e) dspDelRow());
uibutton(g5c,'Text','ファイルから取込','ButtonPushedFcn',@(s,e) dspImport());
W.dspT = uitable(g5b,'Data',cell(0,4), ...
    'ColumnName',{'名前','分布','p1','p2'}, ...
    'ColumnFormat',{'char',{'uniform','normal','normal3'},'numeric','numeric'}, ...
    'ColumnEditable',true(1,4));

%% ---- 再生 ----
p7 = uipanel(gtP,'Title','再生');
g7 = uigridlayout(p7,[1 4],'ColumnWidth',{'fit','1x','fit','1x'},'Padding',[6 4 6 4]);
uilabel(g7,'Text','速度 (実時間比)'); W.spd = uieditfield(g7,'numeric','Value',4);
uilabel(g7,'Text','対象');
W.animSrc = uidropdown(g7,'Items',{'閉ループ','計画'},'Value','閉ループ');

%% ---- ログ ----
W.log = uitextarea(g,'Editable','off','Value',{'準備完了. まず [計画] を実行してください.'});

%% ================= 右: 表示タブ =================
tg = uitabgroup(gm);
tb1 = uitab(tg,'Title','アニメーション');
ga = uigridlayout(tb1,[1 1],'Padding',[4 4 4 4]);
W.axAnim = uiaxes(ga);
tb5 = uitab(tg,'Title','計画');
gp5 = uigridlayout(tb5,[3 3],'RowHeight',{64,'1x','1x'},'Padding',[4 4 4 4],'RowSpacing',4,'ColumnSpacing',4);
W.tdPlan = uitable(gp5,'Data',{},'RowName',{});
W.tdPlan.Layout.Row = 1;  W.tdPlan.Layout.Column = [1 3];
W.axPlan = gobjects(1,6);
for i = 1:6, W.axPlan(i) = uiaxes(gp5); end
tb2 = uitab(tg,'Title','閉ループ');
gp2 = uigridlayout(tb2,[4 3],'RowHeight',{64,'1x','1x','1x'},'Padding',[4 4 4 4],'RowSpacing',4,'ColumnSpacing',4);
W.tdCL = uitable(gp2,'Data',{},'RowName',{});
W.tdCL.Layout.Row = 1;  W.tdCL.Layout.Column = [1 3];
W.axPlot = gobjects(1,9);
for i = 1:9, W.axPlot(i) = uiaxes(gp2); end
tb4 = uitab(tg,'Title','風況');
gw = uigridlayout(tb4,[1 1],'Padding',[4 4 4 4]);
W.axWind = uiaxes(gw);
tb3 = uitab(tg,'Title','MCS');
gm3 = uigridlayout(tb3,[2 2],'Padding',[4 4 4 4],'RowSpacing',4,'ColumnSpacing',4);
W.axMcs3d = uiaxes(gm3);                       % 飛行軌道 鳥瞰図 (左, 縦2枠)
W.axMcs3d.Layout.Row = [1 2];  W.axMcs3d.Layout.Column = 1;
W.axMcs1 = uiaxes(gm3);
W.axMcs1.Layout.Row = 1;  W.axMcs1.Layout.Column = 2;
W.axMcs2 = uiaxes(gm3);
W.axMcs2.Layout.Row = 2;  W.axMcs2.Layout.Column = 2;

S = struct('prob',[],'sol',[],'cfg',[],'R',[]);
setDefaults();
updateWindPlot();

%% ================= コールバック =================
function say(msg)
    W.log.Value = [{sprintf('[%s] %s', datestr(now,'HH:MM:SS'), msg)}; W.log.Value];
    drawnow;
end

function d = busy(ttl, msg)
    %% GUI上の進行ポップアップ (%バー表示). onCleanup で必ず閉じる.
    d = uiprogressdlg(fig,'Title',ttl,'Message',msg,'Value',0);
    drawnow;
end

function finish(d)
    %% 完了時に 100% を明示表示してから閉じる
    try, d.Value = 1;  d.Message = '完了 (100%)';  drawnow;  pause(0.4); catch, end
end

function oops(ME, ttl)
    say(['エラー: ' ME.message]);
    uialert(fig, ME.message, ttl, 'Icon','error');
end

function setDefaults()
    if strcmp(W.veh.Value,'starship')
        [c0,d0] = scpk.model6();
        W.alt.Value=1200; W.dr.Value=-325; W.cr.Value=0; W.vd.Value=80; W.vh.Value=0;
    else
        [c0,d0] = scpk.modelFalcon9();
        W.alt.Value=2200; W.dr.Value=-40; W.cr.Value=0; W.vd.Value=240; W.vh.Value=10;
    end
    v = c0.veh;
    W.mDry.Value = v.dryMass/1e3;   W.mPro.Value = v.landingProp/1e3;
    W.Lb.Value = v.Lb;              W.Rb.Value = v.R;
    W.nE.Value = v.nEngine;         W.Te.Value = v.thrustPerEng/1e3;
    W.isp.Value = v.Isp;            W.thrM.Value = v.throttleMin;
    W.tvc.Value = rad2deg(v.tvcMax);
    %% 派生量 (自動計算値を表示. 以降ユーザー編集値がそのまま使われる)
    W.Ixx.Value = d0.Ixx/1e3;  W.Iyy.Value = d0.Iyy/1e3;  W.Izz.Value = d0.Izz/1e3;
    W.rTx.Value = d0.rTx;      W.rhoA.Value = d0.rho;
    W.cdA.Value = d0.CdAx;     W.cdS.Value = d0.CdSide;   W.aSc.Value = d0.aeroScale;
    W.lod.Value = d0.LoverD;   W.vSrf.Value = d0.VrefSurf; W.sGn.Value = d0.surfGain;
    W.kFd.Value = d0.kFlapDrag; W.hMn.Value = d0.hmin_m;  W.wMx.Value = d0.wMaxDeg;
    %% 計画・追従・制御の既定値を機体テンプレートから取得 (機体ごとに調整値が違う.
    %% 例: wFuel は starship 25 / falcon9 15. 固定値だと他機体で着陸失敗する)
    pT = scpProblem(W.veh.Value);
    W.wF.Value   = pT.opt.wFuel;
    W.tolP.Value = pT.opt.tol.pos;   W.tolV.Value = pT.opt.tol.vel;
    lamT = pT.opt.lamTerm;
    if ~isempty(pT.passes) && isfield(pT.passes(end).set,'lamTerm')
        lamT = pT.passes(end).set.lamTerm;
    end
    W.lamT.Value = round(log10(lamT));
    W.ndF.Value  = 1;
    W.wPos.Value = pT.track.wPos;    W.wVel.Value = pT.track.wVel;
    W.wQt.Value  = pT.track.wQuat;   W.wRt.Value  = pT.track.wRate;
    W.H.Value    = pT.track.H;
    if isfield(pT,'errTrig'), W.eTr.Value = pT.errTrig; else, W.eTr.Value = 25; end
    if isfield(pT,'ctlModeForce') && strcmp(pT.ctlModeForce,'inner')
        W.ctl.Value = '方式2: 内ループ+アクチュエータ';
    else
        W.ctl.Value = '方式1: MPC直接';
    end
    %% 制御タブ: 誘導・周期をテンプレート値へ (内ループ/アクチュエータは共通既定)
    gT = @(f,d) getNested(struct('p',pT),'p',f,d);   % テンプレートに無い項目は既定値
    W.refS.Value = tern(strcmpi(gT('refSync','time'),'alt'), '高度同期 (alt)', '時刻同期 (time)');
    W.vFB.Value  = gT('velFB',0);
    W.vFBi.Value = gT('velFBi',0);
    W.latF.Value = gT('latFreezeAlt',0);
    W.cutA.Value = gT('cutoffAlt',0);
    W.cutV.Value = -0.5;
    W.wnA.Value = 1.2;  W.ztA.Value = 0.9;  W.tauT.Value = 0.10;
    W.fG.Value = 6;  W.ztG.Value = 0.707;  W.tauF.Value = 0.20;  W.aRL.Value = false;
    W.tLd.Value = 0;
    W.dtC.Value = pT.track.dtCtrl;  W.dtP.Value = pT.track.dtPlant;
    okc = gT('okCrit', struct('horiz',30,'vz',5,'tilt',10));   % 成功判定
    W.okH.Value = okc.horiz;  W.okV.Value = okc.vz;  W.okT.Value = okc.tilt;
    dfnV = dspDefaultFile();                      % 変動定義ファイルも機体に追随させる
    if ~isempty(dfnV), W.mcsF.Value = dfnV; end   % (他機体の絶対値諸元が混入すると
                                                  %  T/W<1等で全ラン墜落する. 実測)
    W.dspT.Data = dspCatalog(dfnV);               % MCS変動表: 全パラメータ一覧+機体既定
    S.prob = [];  S.sol = [];  S.R = [];
    say(sprintf('機体: %s (諸元/初期条件/計画・制御既定をテンプレート値にリセット)', W.veh.Value));
end

function prob = buildProb()
    ov = struct('dryMass',W.mDry.Value*1e3, 'landingProp',W.mPro.Value*1e3, ...
                'Lb',W.Lb.Value, 'R',W.Rb.Value, 'nEngine',W.nE.Value, ...
                'thrustPerEng',W.Te.Value*1e3, 'Isp',W.isp.Value, ...
                'throttleMin',W.thrM.Value, 'tvcMax',deg2rad(W.tvc.Value), ...
                'Ixx',W.Ixx.Value*1e3, 'Iyy',W.Iyy.Value*1e3, 'Izz',W.Izz.Value*1e3, ...
                'rTx',W.rTx.Value, 'rho',W.rhoA.Value, ...
                'CdAx',W.cdA.Value, 'CdSide',W.cdS.Value, 'aeroScale',W.aSc.Value, ...
                'LoverD',W.lod.Value, 'VrefSurf',W.vSrf.Value, 'surfGain',W.sGn.Value, ...
                'kFlapDrag',W.kFd.Value, 'hmin_m',W.hMn.Value, 'wMaxDeg',W.wMx.Value, ...
                'atmIsa',double(strcmp(W.atm.Value,'ISA標準大気')), 'hPad',W.hPad.Value);
    prob = scpProblem(W.veh.Value, ov);
    if W.ndF.Value ~= 1, prob = scpSetNodes(prob, W.ndF.Value); end
    prob.windProf = getWindProf();               % 風況プロファイル (閉ループ/MCSへ)
    if W.windTune.Value, prob = scpWindTune(prob); end   % 強風レシピ (環境タブ)
    q0 = prob.x0(7:10);
    vI = [-W.vd.Value; 0; W.vh.Value];
    vB0 = quat2dcm(q0.')*vI;
    prob.x0 = [W.alt.Value; W.cr.Value; W.dr.Value; vB0; q0; 0;0;0; prob.cfg.m0];
    prob.opt.tol.pos = W.tolP.Value;  prob.opt.tol.vel = W.tolV.Value;
    prob.opt.wFuel = W.wF.Value;
    for k = 1:numel(prob.passes)
        if isfield(prob.passes(k).set,'lamTerm')
            prob.passes(k).set.lamTerm = min(prob.passes(k).set.lamTerm, 10^W.lamT.Value);
        end
    end
    prob.passes(end).set.lamTerm = 10^W.lamT.Value;
    prob.track.wPos = W.wPos.Value;  prob.track.wVel = W.wVel.Value;
    prob.track.wQuat = W.wQt.Value;  prob.track.wRate = W.wRt.Value;
    prob.track.H = W.H.Value;
end

function doPlan()
    d = busy('計画', '軌道計画を求解中... (コールドスタート+調整連鎖: 約1分)');
    c = onCleanup(@() delete(d));
    say(sprintf('計画を求解中... [%s]', condStr()));
    try
        S.prob = buildProb();
        pf = @(frac,msg) setProg(d, frac, msg);
        [S.sol, S.cfg] = scpPlan(S.prob, false, pf);
        finish(d);
        plotPlanTrend(S.sol, S.cfg, W.axPlan);   % 計画トレンドを右の「計画」タブへ
        fillTd(W.tdPlan, touchdownStats(S.sol, S.cfg));
        tg.SelectedTab = tb5;
        rE = S.sol.r(:,end);
        msg = sprintf('計画完了: tf=%.1fs 終端高度%.1fm 水平%.1fm 燃料%.2ft nu=%.1e', ...
            S.sol.tf, rE(1), hypot(rE(2),rE(3)), S.sol.propellant/1e3, S.sol.virtCtrl);
        say(msg);
        if S.sol.virtCtrl > 1e-3
            uialert(fig, sprintf(['%s\n\n警告: 仮想制御 nu が残っており計画は完全' ...
                '収束していません。結果は物理的に無効な可能性があります' ...
                '(フェーズ時間の箱・重み・初期条件を見直してください)'], msg), ...
                '計画完了 (未収束)', 'Icon','warning');
        else
            uialert(fig, msg, '計画完了', 'Icon','success');
        end
    catch ME
        oops(ME, '計画エラー');
    end
end

function doCL()
    if isempty(S.sol)
        uialert(fig,'先に [計画] を実行してください','閉ループ','Icon','warning'); return;
    end
    S.prob.windProf = getWindProf();   % 風は計画に入らないため実行時点の環境タブを反映
    d = busy('閉ループ', '閉ループシミュレーション実行中...');
    c = onCleanup(@() delete(d));
    say(sprintf('閉ループ実行中... [%s]', condStr()));
    try
        prm = struct('thrEff',W.thr.Value, 'windY',W.wnd.Value, ...
                     'navJump',W.nav.Value, 'errTrig',W.eTr.Value, ...
                     'dr0',[W.dr0a.Value; W.dr0c.Value; W.dr0d.Value], ...
                     'dvB0',[W.dv0x.Value; W.dv0y.Value; W.dv0z.Value]);
        if startsWith(W.ctl.Value,'方式2'), prm.ctlMode = 'inner'; else, prm.ctlMode = 'direct'; end
        prm = ctlPrm(prm);              % 制御タブの設定を反映
        prm.progressFcn = @(frac) setProg(d, frac, sprintf('シミュレーション %.0f%%', frac*100));
        S.R = scpClosedLoop(S.prob, prm);
        finish(d);
        xE = S.R.xEnd;  q = xE(7:10)/norm(xE(7:10));
        rdI = quat2dcm(q.').'*xE(4:6);
        say(sprintf('閉ループ完了 (%s): 水平%.2fm |v|%.2fm/s 傾斜%.2fdeg 再計画%d回', ...
            prm.ctlMode, hypot(xE(2),xE(3)), norm(rdI), ...
            acosd(max(-1,min(1,1-2*(q(3)^2+q(4)^2)))), S.R.rp.n));
        plotClosedLoop(S.sol, S.R.log, S.cfg, W.axPlot);
        fillTd(W.tdCL, touchdownStats(S.R.xEnd, S.cfg));
        tg.SelectedTab = tb2;
    catch ME
        oops(ME, '閉ループエラー');
    end
end

function doAnim()
    try
        aopt = struct('speed',W.spd.Value,'fps',20,'style',W.veh.Value);
        tg.SelectedTab = tb1;  drawnow;
        if strcmp(W.animSrc.Value,'閉ループ') && ~isempty(S.R)
            say('閉ループ飛行を再生...');
            animateVehicleAx(W.axAnim, S.R.log.t, S.R.log.x, S.R.log.u, S.cfg, aopt);
        elseif ~isempty(S.sol)
            say('計画軌道を再生...');
            Xp = [S.sol.r; S.sol.v; S.sol.q; S.sol.w; S.sol.m];
            animateVehicleAx(W.axAnim, S.sol.t, Xp, S.sol.uhat, S.cfg, aopt);
        else
            uialert(fig,'再生する結果がありません. 先に [計画] を実行してください','再生','Icon','warning');
        end
    catch ME
        oops(ME, '再生エラー');
    end
end

function doMCS()
    if isempty(S.prob)
        uialert(fig,'先に [計画] を実行してください','MCS','Icon','warning'); return;
    end
    S.prob.windProf = getWindProf();   % 風は計画に入らないため実行時点の環境タブを反映
    %% 変動定義ファイルの機体不一致ガード (他機体の絶対値諸元は全ラン墜落の原因)
    if strcmp(W.mcsSrc.Value,'ファイル')
        other = tern(strcmp(W.veh.Value,'starship'), 'falcon9', 'starship');
        if contains(W.mcsF.Value, other)
            sel = uiconfirm(fig, sprintf(['選択中の変動定義「%s」は %s 用です。機体諸元が' ...
                '絶対値で振られるため %s に適用すると全ラン失敗します。続行しますか?'], ...
                W.mcsF.Value, other, W.veh.Value), 'MCS', ...
                'Options',{'続行','中止'}, 'DefaultOption',2, 'Icon','warning');
            if strcmp(sel,'中止'), return; end
        end
    end
    d = busy('モンテカルロ', sprintf('MCS %dラン%s: 準備中...%s', ...
        W.mcsN.Value, tern(W.mcsPar.Value,' (並列)',''), ...
        tern(W.mcsPar.Value,' 初回はプール起動に30-60秒かかります','')));
    c = onCleanup(@() delete(d));
    say(sprintf('MCS %dラン実行中%s...', W.mcsN.Value, tern(W.mcsPar.Value,' (並列)','')));
    try
        mprm = struct('parallel',W.mcsPar.Value, 'noPlot',1);
        if startsWith(W.ctl.Value,'方式2'), mprm.ctlMode = 'inner'; else, mprm.ctlMode = 'direct'; end
        mprm.errTrig = W.eTr.Value;
        mprm.okCrit = struct('horiz',W.okH.Value,'vz',W.okV.Value,'tilt',W.okT.Value);
        mprm = ctlPrm(mprm);            % 制御タブの設定を反映
        mprm.progressFcn = @(done,N) setProg(d, done/N, sprintf('ラン %d/%d 完了 (%.0f%%)', done, N, 100*done/N));
        if strcmp(W.mcsSrc.Value,'GUI表')
            df = W.dspT.Data;                        % cell {名前,分布,p1,p2} を直接渡す
            act = true(size(df,1),1);                % 変動なしの行は除外
            for iD = 1:size(df,1)
                if strcmp(df{iD,2},'uniform'), act(iD) = df{iD,3} ~= df{iD,4};
                else, act(iD) = df{iD,4} ~= 0; end
            end
            df = df(act,:);
            if isempty(df)
                error('変動が設定された行がありません。GUI表で p2 (σ) か上下限を設定してください');
            end
        else
            df = W.mcsF.Value;
            if endsWith(df,'.json'), df = fullfile(proj,'config',df); end
        end
        out = scpMCS(S.prob, df, W.mcsN.Value, mprm);   % probの閉ループ設定を引継ぐ
        finish(d);
        h = [out.res.horiz];  v = [out.res.vTd];  tl = [out.res.tilt];
        plotMcsBirdseye(W.axMcs3d, out.res);
        title(W.axMcs3d, sprintf('飛行軌道 鳥瞰 (%dラン, 青=成功/赤=NG)', out.N));
        cla(W.axMcs1); scatter(W.axMcs1, h, v, 40, tl, 'filled'); grid(W.axMcs1,'on');
        colorbar(W.axMcs1);
        xlabel(W.axMcs1,'水平誤差 [m]'); ylabel(W.axMcs1,'接地速度 [m/s]');
        title(W.axMcs1,'着陸精度 (色=傾斜deg)');
        cla(W.axMcs2); histogram(W.axMcs2, h, 12); grid(W.axMcs2,'on');
        xlabel(W.axMcs2,'水平誤差 [m]'); ylabel(W.axMcs2,'ラン数');
        tg.SelectedTab = tb3;
        say(sprintf('MCS完了: 成功率%.0f%% 水平max %.1fm', ...
            100*mean([out.res.ok]), max(h)));
    catch ME
        oops(ME, 'MCSエラー');
    end
end

function doZip()
    d = busy('コード生成', '組み込み用Cコードを生成中... (数分)');
    c = onCleanup(@() delete(d));
    say('コード生成中 (数分)...');
    try
        setProg(d, 0.15, sprintf('MEX/lib コード生成中... (例データ: %s)', W.veh.Value));
        zipf = scpCodegenZip(true, W.veh.Value);
        setProg(d, 0.95, 'パッケージ化...');
        finish(d);
        say(['完了: ' zipf]);
        uialert(fig, sprintf('生成完了:\n%s', zipf), 'コード生成', 'Icon','success');
    catch ME
        oops(ME, 'コード生成エラー');
    end
end

function setProg(d, frac, msg)
    try
        d.Value = max(0, min(1, frac));
        if nargin >= 3 && ~isempty(msg), d.Message = msg; end
        drawnow limitrate;
    catch
    end
end

function prm = ctlPrm(prm)
    %% 制御タブ (誘導/内ループ/アクチュエータ/周期) の値を閉ループ prm へ
    prm.refSync = tern(contains(W.refS.Value,'alt'), 'alt', 'time');
    prm.velFB = W.vFB.Value;          prm.velFBi = W.vFBi.Value;
    prm.latFreezeAlt = W.latF.Value;
    prm.cutoffAlt = W.cutA.Value;     prm.cutoffV = W.cutV.Value;
    prm.wnAtt = W.wnA.Value;          prm.ztAtt = W.ztA.Value;
    prm.tauThr = W.tauT.Value;        prm.fGim = W.fG.Value;
    prm.ztGim = W.ztG.Value;          prm.tauFlap = W.tauF.Value;
    prm.thrLead = W.tLd.Value;
    prm.actRateLim = double(W.aRL.Value);
    prm.dtMpc = W.dtC.Value;          prm.dtPlant = W.dtP.Value;
end

function fillTd(tbl, st)
    %% 接地状態サマリを表に表示. 成功判定 (MCSタブで編集可) に照らして色分け:
    %% 緑=判定内 / 赤=判定超過 / 白=判定対象外の参考値
    okc = struct('horiz',W.okH.Value,'vz',W.okV.Value,'tilt',W.okT.Value);
    tbl.ColumnName = {'水平誤差 [m]','クロス [m]','DR [m]','鉛直速度 [m/s]', ...
                      '水平速度 [m/s]','傾斜 [deg]','角速度 [deg/s]','残燃料 [t]'};
    tbl.Data = {sprintf('%.1f',st.horiz), sprintf('%.1f',st.cr), sprintf('%.1f',st.dr), ...
                sprintf('%+.2f',st.vz), sprintf('%.2f',st.vh), sprintf('%.2f',st.tilt), ...
                sprintf('%.2f',st.wDeg), sprintf('%.2f',st.fuel)};
    removeStyle(tbl);
    gOK = uistyle('BackgroundColor',[0.85 1.0 0.85]);
    gNG = uistyle('BackgroundColor',[1.0 0.82 0.82]);
    vTot = hypot(st.vz, st.vh);                     % 判定は速度の合成ノルム
    chk = {1, st.horiz <= okc.horiz; 4, vTot <= okc.vz; 6, st.tilt <= okc.tilt};
    for ii = 1:size(chk,1)
        if chk{ii,2}, addStyle(tbl, gOK, 'cell', [1 chk{ii,1}]);
        else,         addStyle(tbl, gNG, 'cell', [1 chk{ii,1}]); end
    end
end

function s = condStr()
    %% 実行条件のエコー (隠れ状態による「再現できない」事故の防止):
    %% 風テーブルは機体切替でも残るため, 何が適用されるかを毎回明示する
    wpG = getWindProf();
    if isempty(wpG), ws = '風なし';
    else, ws = sprintf('風あり max%.1fm/s', max(abs([wpG.wy; wpG.wz])));
    end
    s = sprintf('%s | %s | 強風チューニング%s | %s | %s', W.veh.Value, ws, ...
        tern(W.windTune.Value,'ON','OFF'), tern(strcmp(W.atm.Value,'ISA標準大気'),'ISA','一定密度'), ...
        tern(startsWith(W.ctl.Value,'方式2'),'方式2','方式1'));
end

function wp = getWindProf()
    %% 風況テーブル -> struct('h','wy','wz'). 2行未満は無効 ([] = 無風).
    D = W.wndT.Data;
    if size(D,1) < 2, wp = []; return; end
    try
        wp = loadWindProfile(struct('h',D(:,1),'wy',D(:,2),'wz',D(:,3)));
    catch ME
        say(['風プロファイル無効: ' ME.message]);  wp = [];
    end
end

function updateWindPlot(show)
    %% 風分布を右の「風況」タブに描画. show=true でタブを前面に出す
    plotWindProfile(W.axWind, getWindProf());
    if nargin >= 1 && show, tg.SelectedTab = tb4; end
end

function windAddRow()
    D = W.wndT.Data;
    if isempty(D), D = [0 0 0]; else, D(end+1,:) = [D(end,1)+200, D(end,2:3)]; end
    W.wndT.Data = D;  updateWindPlot(true);
end

function windDelRow()
    D = W.wndT.Data;
    if ~isempty(D), W.wndT.Data = D(1:end-1,:); end
    updateWindPlot(true);
end

function windClear()
    W.wndT.Data = zeros(0,3);  updateWindPlot();
end

function windLoadJson()
    try
        [fn,fp] = uigetfile('*.json','風プロファイルを読込 (h/wy/wz)', fullfile(proj,'config'));
        if isequal(fn,0), return; end
        wp = loadWindProfile(fullfile(fp,fn));
        W.wndT.Data = [wp.h, wp.wy, wp.wz];
        updateWindPlot(true);
        say(['風プロファイル読込: ' fn]);
    catch ME
        oops(ME, '風プロファイル読込エラー');
    end
end

function C = dspCatalog(dfn)
    %% 設定可能な全変動パラメータの一覧 (公称値, 変動0で初期化).
    %% DFN (変動定義ファイル) を与えるとその項目を上書きして反映する.
    if strcmp(W.veh.Value,'starship'), [c0,d0] = scpk.model6();
    else, [c0,d0] = scpk.modelFalcon9(); end
    v = c0.veh;
    C = { ...  %% --- 環境・外乱 ---
      'thrEff',      'uniform', 1.0,           1.0;
      'windY',       'normal3', 0,             0;
      'windScale',   'normal3', 1.0,           0;
      'navJump',     'normal3', 0,             0;
      ...  %% --- 初期分散 (位置[m] / 機体系速度[m/s]) ---
      'dr0x','normal3',0,0; 'dr0y','normal3',0,0; 'dr0z','normal3',0,0;
      'dvBx','normal3',0,0; 'dvBy','normal3',0,0; 'dvBz','normal3',0,0;
      ...  %% --- 機体諸元 (絶対値. プラント側モデルのみ差替) ---
      'dryMass',     'normal3', v.dryMass,     0;
      'landingProp', 'normal3', v.landingProp, 0;
      'Lb',          'normal3', v.Lb,          0;
      'R',           'normal3', v.R,           0;
      'thrustPerEng','normal3', v.thrustPerEng,0;
      'Isp',         'normal3', v.Isp,         0;
      'throttleMin', 'normal3', v.throttleMin, 0;
      'throttleMax', 'normal3', v.throttleMax, 0;
      'tvcMax',      'normal3', v.tvcMax,      0;
      'Ixx','normal3',d0.Ixx,0; 'Iyy','normal3',d0.Iyy,0; 'Izz','normal3',d0.Izz,0;
      'rTx',         'normal3', d0.rTx,        0;
      'rho',         'normal3', d0.rho,        0;
      'CdAx','normal3',d0.CdAx,0; 'CdSide','normal3',d0.CdSide,0;
      'aeroScale',   'normal3', d0.aeroScale,  0;
      'LoverD',      'normal3', d0.LoverD,     0;
      'VrefSurf',    'normal3', d0.VrefSurf,   0;
      'surfGain',    'normal3', d0.surfGain,   0;
      'kFlapDrag',   'normal3', d0.kFlapDrag,  0;
      'wMaxDeg',     'normal3', d0.wMaxDeg,    0;
      'hPad',        'normal3', d0.hPad,       0};
    if nargin >= 1 && ~isempty(dfn)
        try
            if endsWith(dfn,'.json'), sp = loadDispersions(fullfile(proj,'config',dfn));
            else, sp = loadDispersions(dfn); end
            for ii = 1:size(sp,1)
                jj = find(strcmp(C(:,1), sp{ii,1}), 1);
                if isempty(jj), C(end+1,:) = sp(ii,:); %#ok<AGROW> % 一覧外 (prm系) は追記
                else, C(jj,2:4) = sp(ii,2:4); end
            end
        catch
        end
    end
end

function dfn = dspDefaultFile()
    %% 機体テンプレートの既定変動定義ファイル名
    if strcmp(W.veh.Value,'starship'), dfn = 'dispersions_starship';
    else, dfn = 'dispersions_falcon9.json'; end
    if ~any(strcmp(W.mcsF.Items, dfn)), dfn = ''; end
end

function dspReset()
    W.dspT.Data = dspCatalog(dspDefaultFile());
    say('変動定義を全パラメータ一覧にリセット (機体既定の変動を反映)');
end

function dspAddRow()
    W.dspT.Data = [W.dspT.Data; {'errTrig','normal3',0,0}];
end

function dspDelRow()
    D = W.dspT.Data;
    if ~isempty(D), W.dspT.Data = D(1:end-1,:); end
end

function dspImport()
    %% 「ファイル」ドロップダウンで選択中の変動定義を一覧へ反映し, ソースをGUI表へ
    try
        W.dspT.Data = dspCatalog(W.mcsF.Value);
        W.mcsSrc.Value = 'GUI表';
        say(sprintf('変動定義を取込: %s (以降はGUI表の値でMCS実行)', W.mcsF.Value));
    catch ME
        oops(ME, '変動定義取込エラー');
    end
end

function doGenScript()
    %% 現在のGUI設定と同一の解析 (問題設定->計画->閉ループ->MCS) を再現する
    %% スタンドアロンMATLABスクリプトを書き出す
    try
        [fn,fp] = uiputfile('*.m','再現スクリプトを保存', ...
            fullfile(proj, sprintf('repro_%s.m', W.veh.Value)));
        if isequal(fn,0), return; end
        n = @(v) sprintf('%.10g', v);                 % 数値 -> 文字列
        L = {};
        L{end+1} = sprintf('%%%% SCP着陸解析 再現スクリプト (scpApp で自動生成: %s)', ...
            char(datetime('now','Format','yyyy-MM-dd HH:mm')));
        L{end+1} = '%  GUIで設定した内容と同一の 問題設定 -> 計画 -> 閉ループ (-> MCS) を実行する.';
        L{end+1} = '%  事前にプロジェクト直下で setup を実行しておくこと.';
        L{end+1} = '';
        L{end+1} = 'DO.mcs = false;                     % true でモンテカルロも実行';
        L{end+1} = '';
        L{end+1} = '%% 1. 問題設定 (機体諸元・派生量・環境)';
        L{end+1} = 'ov = struct( ...';
        L{end+1} = sprintf('    ''dryMass'',%s, ''landingProp'',%s, ''Lb'',%s, ''R'',%s, ...', ...
            n(W.mDry.Value*1e3), n(W.mPro.Value*1e3), n(W.Lb.Value), n(W.Rb.Value));
        L{end+1} = sprintf('    ''nEngine'',%s, ''thrustPerEng'',%s, ''Isp'',%s, ...', ...
            n(W.nE.Value), n(W.Te.Value*1e3), n(W.isp.Value));
        L{end+1} = sprintf('    ''throttleMin'',%s, ''tvcMax'',%s, ...', ...
            n(W.thrM.Value), n(deg2rad(W.tvc.Value)));
        L{end+1} = sprintf('    ''Ixx'',%s, ''Iyy'',%s, ''Izz'',%s, ''rTx'',%s, ''rho'',%s, ...', ...
            n(W.Ixx.Value*1e3), n(W.Iyy.Value*1e3), n(W.Izz.Value*1e3), n(W.rTx.Value), n(W.rhoA.Value));
        L{end+1} = sprintf('    ''CdAx'',%s, ''CdSide'',%s, ''aeroScale'',%s, ''LoverD'',%s, ...', ...
            n(W.cdA.Value), n(W.cdS.Value), n(W.aSc.Value), n(W.lod.Value));
        L{end+1} = sprintf('    ''VrefSurf'',%s, ''surfGain'',%s, ''kFlapDrag'',%s, ...', ...
            n(W.vSrf.Value), n(W.sGn.Value), n(W.kFd.Value));
        L{end+1} = sprintf('    ''hmin_m'',%s, ''wMaxDeg'',%s, ''atmIsa'',%d, ''hPad'',%s);', ...
            n(W.hMn.Value), n(W.wMx.Value), double(strcmp(W.atm.Value,'ISA標準大気')), n(W.hPad.Value));
        L{end+1} = sprintf('prob = scpProblem(''%s'', ov);', W.veh.Value);
        L{end+1} = '';
        L{end+1} = '% 初期条件';
        L{end+1} = 'q0 = prob.x0(7:10);';
        L{end+1} = sprintf('vB0 = quat2dcm(q0.'')*[%s; 0; %s];   %% 慣性 [降下(-上); 0; 水平] -> 機体系', ...
            n(-W.vd.Value), n(W.vh.Value));
        L{end+1} = sprintf('prob.x0 = [%s; %s; %s; vB0; q0; 0;0;0; prob.cfg.m0];', ...
            n(W.alt.Value), n(W.cr.Value), n(W.dr.Value));
        L{end+1} = '';
        L{end+1} = '% 計画の重み / スケーリング';
        L{end+1} = sprintf('prob.opt.tol.pos = %s;  prob.opt.tol.vel = %s;', n(W.tolP.Value), n(W.tolV.Value));
        L{end+1} = sprintf('prob.opt.wFuel = %s;', n(W.wF.Value));
        L{end+1} = 'for k = 1:numel(prob.passes)';
        L{end+1} = '    if isfield(prob.passes(k).set,''lamTerm'')';
        L{end+1} = sprintf('        prob.passes(k).set.lamTerm = min(prob.passes(k).set.lamTerm, 10^%s);', n(W.lamT.Value));
        L{end+1} = '    end';
        L{end+1} = 'end';
        L{end+1} = sprintf('prob.passes(end).set.lamTerm = 10^%s;', n(W.lamT.Value));
        L{end+1} = '';
        L{end+1} = '% 追従MPC';
        L{end+1} = sprintf('prob.track.wPos = %s;  prob.track.wVel = %s;', n(W.wPos.Value), n(W.wVel.Value));
        L{end+1} = sprintf('prob.track.wQuat = %s;  prob.track.wRate = %s;  prob.track.H = %s;', ...
            n(W.wQt.Value), n(W.wRt.Value), n(W.H.Value));
        L{end+1} = '';
        D = W.wndT.Data;
        if size(D,1) >= 2
            L{end+1} = '% 風況プロファイル (高度[m] / クロス風[m/s] / ダウンレンジ風[m/s])';
            L{end+1} = sprintf('prob.windProf = loadWindProfile(struct( ...');
            L{end+1} = sprintf('    ''h'',%s, ...',  mat2str(D(:,1).', 10));
            L{end+1} = sprintf('    ''wy'',%s, ...', mat2str(D(:,2).', 10));
            L{end+1} = sprintf('    ''wz'',%s));',   mat2str(D(:,3).', 10));
        else
            L{end+1} = 'prob.windProf = [];                 % 風プロファイルなし';
        end
        if W.windTune.Value
            L{end+1} = 'prob = scpWindTune(prob);           % 強風チューニング (環境タブ)';
        end
        L{end+1} = '';
        L{end+1} = '%% 2. 軌道計画';
        L{end+1} = '[sol, cfg] = scpPlan(prob);';
        L{end+1} = 'plotPlanTrend(sol, cfg);';
        L{end+1} = 'disp(''--- 計画の接地状態 ---'');  disp(touchdownStats(sol, cfg));';
        L{end+1} = '';
        L{end+1} = '%% 3. 閉ループ (追従MPC + 再計画)';
        L{end+1} = sprintf('prm = struct(''thrEff'',%s, ''windY'',%s, ''navJump'',%s, ''errTrig'',%s, ...', ...
            n(W.thr.Value), n(W.wnd.Value), n(W.nav.Value), n(W.eTr.Value));
        L{end+1} = sprintf('             ''dr0'',[%s;%s;%s], ''dvB0'',[%s;%s;%s], ''ctlMode'',''%s'', ...', ...
            n(W.dr0a.Value), n(W.dr0c.Value), n(W.dr0d.Value), ...
            n(W.dv0x.Value), n(W.dv0y.Value), n(W.dv0z.Value), ...
            tern(startsWith(W.ctl.Value,'方式2'),'inner','direct'));
        L{end+1} = sprintf('             ''refSync'',''%s'', ''velFB'',%s, ''velFBi'',%s, ''latFreezeAlt'',%s, ...', ...
            tern(contains(W.refS.Value,'alt'),'alt','time'), n(W.vFB.Value), n(W.vFBi.Value), n(W.latF.Value));
        L{end+1} = sprintf('             ''cutoffAlt'',%s, ''cutoffV'',%s, ''wnAtt'',%s, ''ztAtt'',%s, ...', ...
            n(W.cutA.Value), n(W.cutV.Value), n(W.wnA.Value), n(W.ztA.Value));
        L{end+1} = sprintf('             ''tauThr'',%s, ''fGim'',%s, ''ztGim'',%s, ''tauFlap'',%s, ...', ...
            n(W.tauT.Value), n(W.fG.Value), n(W.ztG.Value), n(W.tauF.Value));
        L{end+1} = sprintf('             ''actRateLim'',%d, ''dtMpc'',%s, ''dtPlant'',%s);', ...
            double(W.aRL.Value), n(W.dtC.Value), n(W.dtP.Value));
        L{end+1} = 'R = scpClosedLoop(prob, prm);';
        L{end+1} = 'plotClosedLoop(sol, R.log, cfg);';
        L{end+1} = 'disp(''--- 閉ループの接地状態 ---'');  disp(touchdownStats(R.xEnd, cfg));';
        L{end+1} = '';
        L{end+1} = '%% 4. モンテカルロ (DO.mcs = true で実行)';
        L{end+1} = 'if DO.mcs';
        if strcmp(W.mcsSrc.Value,'GUI表')
            Dd = W.dspT.Data;
            L{end+1} = '    spec = { ...   % GUI表の変動定義 {名前, 分布, p1, p2}';
            for ii = 1:size(Dd,1)
                L{end+1} = sprintf('        ''%s'', ''%s'', %s, %s;', Dd{ii,1}, Dd{ii,2}, n(Dd{ii,3}), n(Dd{ii,4})); %#ok<AGROW>
            end
            L{end+1} = '        };';
        else
            df = W.mcsF.Value;
            if endsWith(df,'.json'), df = ['fullfile(''config'',''' df ''')']; else, df = ['''' df '''']; end
            L{end+1} = sprintf('    spec = %s;   %% 変動定義ファイル', df);
        end
        L{end+1} = sprintf(['    out = scpMCS(prob, spec, %s, struct(''parallel'',%s, ...\n' ...
            '        ''okCrit'',struct(''horiz'',%s,''vz'',%s,''tilt'',%s)));'], ...
            n(W.mcsN.Value), tern(W.mcsPar.Value,'true','false'), ...
            n(W.okH.Value), n(W.okV.Value), n(W.okT.Value));
        L{end+1} = '    fprintf(''MCS成功率: %.0f%%%%\n'', 100*mean([out.res.ok]));';
        L{end+1} = 'end';
        fid = fopen(fullfile(fp,fn),'w','n','UTF-8');
        fprintf(fid, '%s\n', L{:});  fclose(fid);
        say(['再現スクリプトを生成: ' fn]);
        uialert(fig, sprintf('生成しました:\n%s\n\nsetup 実行後にそのまま走らせれば同じ解析を再現できます。', ...
            fullfile(fp,fn)), 'スクリプト生成', 'Icon','success');
    catch ME
        oops(ME, 'スクリプト生成エラー');
    end
end

function doSaveJson()
    try
        [fn,fp] = uiputfile('*.json','設定を保存', fullfile(proj,'config','settings.json'));
        if isequal(fn,0), return; end
        s = gatherSettings();
        fid = fopen(fullfile(fp,fn),'w','n','UTF-8');
        fwrite(fid, jsonencode(s, 'PrettyPrint', true));  fclose(fid);
        W.jsonLbl.Text = fn;
        say(['設定を保存: ' fn]);
    catch ME
        oops(ME, '設定保存エラー');
    end
end

function doLoadJson()
    try
        [fn,fp] = uigetfile('*.json','設定を読込', fullfile(proj,'config'));
        if isequal(fn,0), return; end
        s = jsondecode(fileread(fullfile(fp,fn)));
        applySettings(s);
        W.jsonLbl.Text = fn;
        say(['設定を読込: ' fn]);
    catch ME
        oops(ME, '設定読込エラー');
    end
end

function s = gatherSettings()
    s.vehicle = W.veh.Value;
    s.ic   = struct('alt',W.alt.Value,'downrange',W.dr.Value,'cross',W.cr.Value, ...
                    'vDescent',W.vd.Value,'vHoriz',W.vh.Value);
    s.veh  = struct('dryMass_t',W.mDry.Value,'prop_t',W.mPro.Value,'Lb_m',W.Lb.Value, ...
                    'R_m',W.Rb.Value,'nEngine',W.nE.Value,'thrustPerEng_kN',W.Te.Value, ...
                    'Isp_s',W.isp.Value,'throttleMin',W.thrM.Value,'tvcMax_deg',W.tvc.Value);
    s.der  = struct('Ixx_tm2',W.Ixx.Value,'Iyy_tm2',W.Iyy.Value,'Izz_tm2',W.Izz.Value, ...
                    'rTx_m',W.rTx.Value,'rho',W.rhoA.Value,'CdAx',W.cdA.Value, ...
                    'CdSide',W.cdS.Value,'aeroScale',W.aSc.Value,'LoverD',W.lod.Value, ...
                    'VrefSurf_ms',W.vSrf.Value,'surfGain',W.sGn.Value, ...
                    'kFlapDrag',W.kFd.Value,'hmin_m',W.hMn.Value,'wMax_degs',W.wMx.Value);
    s.plan = struct('log10LamTerm',W.lamT.Value,'wFuel',W.wF.Value, ...
                    'tolPos_m',W.tolP.Value,'tolVel_ms',W.tolV.Value, ...
                    'nodeFactor',W.ndF.Value);
    s.track= struct('ctlMode',tern(startsWith(W.ctl.Value,'方式2'),'inner','direct'), ...
                    'wPos',W.wPos.Value,'wVel',W.wVel.Value, ...
                    'wQuat',W.wQt.Value,'wRate',W.wRt.Value,'H',W.H.Value);
    s.dist = struct('thrEff',W.thr.Value,'windY',W.wnd.Value, ...
                    'navJump',W.nav.Value,'errTrig',W.eTr.Value, ...
                    'dr0',[W.dr0a.Value W.dr0c.Value W.dr0d.Value], ...
                    'dvB0',[W.dv0x.Value W.dv0y.Value W.dv0z.Value]);
    s.ctl  = struct('refSync',tern(contains(W.refS.Value,'alt'),'alt','time'), ...
                    'velFB',W.vFB.Value,'velFBi',W.vFBi.Value, ...
                    'latFreezeAlt',W.latF.Value,'cutoffAlt',W.cutA.Value,'cutoffV',W.cutV.Value, ...
                    'wnAtt',W.wnA.Value,'ztAtt',W.ztA.Value,'tauThr',W.tauT.Value, ...
                    'fGim',W.fG.Value,'ztGim',W.ztG.Value,'tauFlap',W.tauF.Value, ...
                    'thrLead',W.tLd.Value,'actRateLim',logical(W.aRL.Value), ...
                    'dtMpc',W.dtC.Value,'dtPlant',W.dtP.Value);
    D = W.wndT.Data;
    s.env  = struct('atmIsa',double(strcmp(W.atm.Value,'ISA標準大気')), ...
                    'hPad_m',W.hPad.Value, 'windTune',logical(W.windTune.Value), ...
                    'wind',struct('h',D(:,1),'wy',D(:,2),'wz',D(:,3)));
    Dd = W.dspT.Data;
    ds = struct('name',{},'dist',{},'p1',{},'p2',{});
    for ii = 1:size(Dd,1)
        ds(ii) = struct('name',Dd{ii,1},'dist',Dd{ii,2},'p1',Dd{ii,3},'p2',Dd{ii,4});
    end
    s.mcs  = struct('N',W.mcsN.Value,'parallel',logical(W.mcsPar.Value), ...
                    'source',W.mcsSrc.Value,'dispFile',W.mcsF.Value,'disp',ds, ...
                    'okCrit',struct('horiz',W.okH.Value,'vz',W.okV.Value,'tilt',W.okT.Value));
    s.play = struct('speed',W.spd.Value,'source',W.animSrc.Value);
end

function applySettings(s)
    gs = @(grp,f,d) getNested(s,grp,f,d);
    if isfield(s,'vehicle'), W.veh.Value = s.vehicle; setDefaults(); end
    W.alt.Value = gs('ic','alt',W.alt.Value);
    W.dr.Value  = gs('ic','downrange',W.dr.Value);
    W.cr.Value  = gs('ic','cross',W.cr.Value);
    W.vd.Value  = gs('ic','vDescent',W.vd.Value);
    W.vh.Value  = gs('ic','vHoriz',W.vh.Value);
    W.mDry.Value = gs('veh','dryMass_t',W.mDry.Value);
    W.mPro.Value = gs('veh','prop_t',W.mPro.Value);
    W.Lb.Value   = gs('veh','Lb_m',W.Lb.Value);
    W.Rb.Value   = gs('veh','R_m',W.Rb.Value);
    W.nE.Value   = gs('veh','nEngine',W.nE.Value);
    W.Te.Value   = gs('veh','thrustPerEng_kN',W.Te.Value);
    W.isp.Value  = gs('veh','Isp_s',W.isp.Value);
    W.thrM.Value = gs('veh','throttleMin',W.thrM.Value);
    W.tvc.Value  = gs('veh','tvcMax_deg',W.tvc.Value);
    W.lamT.Value = gs('plan','log10LamTerm',W.lamT.Value);
    W.wF.Value   = gs('plan','wFuel',W.wF.Value);
    W.tolP.Value = gs('plan','tolPos_m',W.tolP.Value);
    W.tolV.Value = gs('plan','tolVel_ms',W.tolV.Value);
    W.ndF.Value  = gs('plan','nodeFactor',W.ndF.Value);
    if strcmp(gs('track','ctlMode','inner'),'inner')
        W.ctl.Value = '方式2: 内ループ+アクチュエータ';
    else
        W.ctl.Value = '方式1: MPC直接';
    end
    W.wPos.Value = gs('track','wPos',W.wPos.Value);
    W.wVel.Value = gs('track','wVel',W.wVel.Value);
    W.wQt.Value  = gs('track','wQuat',W.wQt.Value);
    W.wRt.Value  = gs('track','wRate',W.wRt.Value);
    W.H.Value    = gs('track','H',W.H.Value);
    W.thr.Value  = gs('dist','thrEff',W.thr.Value);
    W.wnd.Value  = gs('dist','windY',W.wnd.Value);
    W.nav.Value  = gs('dist','navJump',W.nav.Value);
    W.eTr.Value  = gs('dist','errTrig',W.eTr.Value);
    d3 = gs('dist','dr0',[W.dr0a.Value W.dr0c.Value W.dr0d.Value]);
    W.dr0a.Value = d3(1);  W.dr0c.Value = d3(2);  W.dr0d.Value = d3(3);
    v3 = gs('dist','dvB0',[W.dv0x.Value W.dv0y.Value W.dv0z.Value]);
    W.dv0x.Value = v3(1);  W.dv0y.Value = v3(2);  W.dv0z.Value = v3(3);
    W.Ixx.Value  = gs('der','Ixx_tm2',W.Ixx.Value);
    W.Iyy.Value  = gs('der','Iyy_tm2',W.Iyy.Value);
    W.Izz.Value  = gs('der','Izz_tm2',W.Izz.Value);
    W.rTx.Value  = gs('der','rTx_m',W.rTx.Value);
    W.rhoA.Value = gs('der','rho',W.rhoA.Value);
    W.cdA.Value  = gs('der','CdAx',W.cdA.Value);
    W.cdS.Value  = gs('der','CdSide',W.cdS.Value);
    W.aSc.Value  = gs('der','aeroScale',W.aSc.Value);
    W.lod.Value  = gs('der','LoverD',W.lod.Value);
    W.vSrf.Value = gs('der','VrefSurf_ms',W.vSrf.Value);
    W.sGn.Value  = gs('der','surfGain',W.sGn.Value);
    W.kFd.Value  = gs('der','kFlapDrag',W.kFd.Value);
    W.hMn.Value  = gs('der','hmin_m',W.hMn.Value);
    W.wMx.Value  = gs('der','wMax_degs',W.wMx.Value);
    W.refS.Value = tern(strcmpi(gs('ctl','refSync','time'),'alt'), '高度同期 (alt)', '時刻同期 (time)');
    W.vFB.Value  = gs('ctl','velFB',W.vFB.Value);
    W.vFBi.Value = gs('ctl','velFBi',W.vFBi.Value);
    W.latF.Value = gs('ctl','latFreezeAlt',W.latF.Value);
    W.cutA.Value = gs('ctl','cutoffAlt',W.cutA.Value);
    W.cutV.Value = gs('ctl','cutoffV',W.cutV.Value);
    W.wnA.Value  = gs('ctl','wnAtt',W.wnA.Value);
    W.ztA.Value  = gs('ctl','ztAtt',W.ztA.Value);
    W.tauT.Value = gs('ctl','tauThr',W.tauT.Value);
    W.fG.Value   = gs('ctl','fGim',W.fG.Value);
    W.ztG.Value  = gs('ctl','ztGim',W.ztG.Value);
    W.tauF.Value = gs('ctl','tauFlap',W.tauF.Value);
    W.tLd.Value  = gs('ctl','thrLead',W.tLd.Value);
    W.aRL.Value  = logical(gs('ctl','actRateLim',W.aRL.Value));
    W.dtC.Value  = gs('ctl','dtMpc',W.dtC.Value);
    W.dtP.Value  = gs('ctl','dtPlant',W.dtP.Value);
    W.atm.Value  = tern(gs('env','atmIsa',1) > 0, 'ISA標準大気', '一定密度');
    W.hPad.Value = gs('env','hPad_m',W.hPad.Value);
    W.windTune.Value = logical(gs('env','windTune',W.windTune.Value));
    wj = gs('env','wind',[]);
    if ~isempty(wj) && isfield(wj,'h') && numel(wj.h) >= 2
        W.wndT.Data = [wj.h(:), wj.wy(:), wj.wz(:)];
    elseif ~isempty(wj)
        W.wndT.Data = zeros(0,3);
    end
    updateWindPlot();
    W.mcsN.Value = gs('mcs','N',W.mcsN.Value);
    W.mcsPar.Value = logical(gs('mcs','parallel',W.mcsPar.Value));
    df = gs('mcs','dispFile','');
    if ~isempty(df) && any(strcmp(W.mcsF.Items, df)), W.mcsF.Value = df; end
    okj = gs('mcs','okCrit',[]);
    if ~isempty(okj)
        W.okH.Value = okj.horiz;  W.okV.Value = okj.vz;  W.okT.Value = okj.tilt;
    end
    srcM = gs('mcs','source','');
    if any(strcmp(W.mcsSrc.Items, srcM)), W.mcsSrc.Value = srcM; end
    dd = gs('mcs','disp',[]);
    if ~isempty(dd)
        nD = numel(dd);  C = cell(nD,4);
        for ii = 1:nD
            if iscell(dd), r = dd{ii}; else, r = dd(ii); end
            C(ii,:) = {r.name, r.dist, r.p1, r.p2};
        end
        W.dspT.Data = C;
    end
    W.spd.Value = gs('play','speed',W.spd.Value);
    src = gs('play','source','');
    if ~isempty(src) && any(strcmp(W.animSrc.Items, src)), W.animSrc.Value = src; end
end
end

function v = getNested(s, grp, f, d)
if isfield(s,grp) && isfield(s.(grp),f) && ~isempty(s.(grp).(f)), v = s.(grp).(f);
else, v = d; end
end

function s = tern(c,a,b), if c, s=a; else, s=b; end, end
