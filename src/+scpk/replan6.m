function [plan2,ok,dbg] = replan6(plan, xNowPhys, tInPlan, nIter)
%REPLAN6  現在状態から残り軌道をウォームスタートで引き直す (オンライン再計画).
%
%   [PLAN2,OK,DBG] = REPLAN6(PLAN, XNOWPHYS, TINPLAN, NITER)
%
%   PLAN     計画状態 struct: .sol (plan6ft の解), .opt (使用オプション),
%            .tiltN (ノード毎傾斜上限), .cfg, .xT
%   XNOWPHYS 現在状態 (物理単位 14)
%   TINPLAN  現計画の時間軸上の現在時刻 [s]
%   NITER    SCP反復数 (RTI: 1-3 推奨)
%
%   やること:
%     1. 現在時刻からアクティブなフェーズを判定し, 完了フェーズのノードを落とす
%     2. アクティブフェーズの時間を残り時間に合わせ, sigma箱を再設定
%     3. 前計画をウォームスタートに plan6ft を NITER 反復
%     4. 受け入れ判定 (nu, 終端妥当性). 不合格なら旧計画を保持 (OK=false)
%
%   See also SCPK.PLAN6FT, RUNCLOSEDLOOPREPLAN
sol = plan.sol;  opt = plan.opt;  cfg = plan.cfg;
ph = sol.phase;  N = numel(ph);
kNow = find(sol.t(1:N) <= tInPlan, 1, 'last');
if isempty(kNow), kNow = 1; end
jc = ph(kNow);                               %% アクティブフェーズ
k0 = find(ph == jc, 1);                      %% そのフェーズの先頭ノード
kEnd = find(ph == jc, 1, 'last');
remJ = max(sol.t(kEnd+1) - tInPlan, 0.4);    %% フェーズ残り時間 [s]

ph2 = ph(k0:end);  eng2 = sol.engSched(k0:end);
o = opt;
o.phase = ph2;  o.engSched = eng2;
o.tiltMaxNode = plan.tiltN(k0:end);
o.maxIter = nIter;  o.verbose = false;
o.useCpp = true;                             %% 再計画のQPは手書きC++で解く
%% (推力下限を上げた参照 (thrMinUp) は温間初期解が即座に主問題不可能になり
%%  全て却下されるため不採用. 過制動対策はプラント誘導側の基数前倒しガード
%%  (runClosedLoopReplan の engGuard) で行う)
sig2 = sol.sigma;  sig2(jc) = remJ;
o.sigMin(jc) = min(o.sigMin(jc), max(0.3, 0.5*remJ));
o.sigMax(jc) = max(1.3*remJ + 0.5, o.sigMin(jc) + 0.3);

%% 経路箱制約 (クロス/ダウンレンジ) を現在状態が入るよう拡張.
%% 風などで公称の箱の外へ流された場合, 元の箱のままでは初期ノードが実行不可能
%% になり再計画が全て却下される. 現在位置 +20m の余裕まで箱を広げる.
mrg = 20;
if isfield(o,'crMax') && ~isempty(o.crMax) && isfinite(o.crMax)
    o.crMax = max(o.crMax, abs(xNowPhys(2)) + mrg);
end
if isfield(o,'drBox') && ~isempty(o.drBox)
    o.drBox = [min(o.drBox(1), xNowPhys(3) - mrg), max(o.drBox(2), xNowPhys(3) + mrg)];
end

ref = struct('xhat', sol.xhat(:,k0:end), 'uhat', sol.uhat(:,k0:end), ...
             'ghat', sol.ghat(k0:end),   'sigma', sig2);

%% 終端鉛直速度を -3 m/s に「熱く」する. ホバー不能機は実最小スロットルでも
%% 正味減速が残るため, v→0 を狙う参照では 2 m/s 級の遅れ側誤差で空中停止 ->
%% カットオフ落下になる (実測 vTd 9-22). 接地時 -3 m/s を狙えば遅れても
%% 停止せず接地まで届き, 進み側は追従が吸収する (okCrit vz には十分収まる)
xT2 = plan.xT;
vBias = -3.0/cfg.sc.V;
xT2(4) = min(xT2(4), vBias);

tS = tic;
[sol2,info] = scpk.plan6ft(xNowPhys, xT2, sig2, cfg, o, ref);
%% --- 磨き段 (オフライン計画の磨きパス相当) ---
%% 再計画の解はそのまま最終的な着陸参照になる. ベースの緩QP (tol 1e-3) の
%% ままだと最適性の取り残しで「終端が数m浮く + 水平20m級の残差」が参照に
%% 残り, それを忠実に追従した機体が接地速度 10 m/s 級で落ちる (MCS実測:
%% 再計画ありランのみ vTd 9-19). ベース反復で形を作り, 厳QPで仕上げる.
o2 = o;  o2.maxIter = 3;
o2.qp.maxIter = max(o.qp.maxIter, 20000);
o2.qp.tolPri  = min(o.qp.tolPri, 1e-5);
o2.qp.tolDua  = min(o.qp.tolDua, 1e-5);
ref2 = struct('xhat',sol2.xhat, 'uhat',sol2.uhat, 'ghat',sol2.ghat, 'sigma',sol2.sigma);
[sol2b,info2] = scpk.plan6ft(xNowPhys, xT2, sol2.sigma, cfg, o2, ref2);
if isfinite(sol2b.tf) && sol2b.virtCtrl <= max(sol2.virtCtrl, 1e-3)
    sol2 = sol2b;                            %% 磨きが有効なときだけ採用
end
dbg.time = toc(tS);
dbg.nIter = info.nIter + info2.nIter;
dbg.qpTime = sum(info.qpTime(1:info.nIter)) + sum(info2.qpTime(1:info2.nIter));
dbg.buildTime = sum(info.buildTime(1:info.nIter)) + sum(info2.buildTime(1:info2.nIter));
dbg.nu = sol2.virtCtrl;

%% --- 受け入れ判定 (不合格なら旧計画を使い続ける) ---
rE = sol2.r(:,end);
ok = isfinite(sol2.tf) && sol2.tf > 0.3 && ...
     sol2.virtCtrl < 1e-2 && ...
     rE(1) < 400 && hypot(rE(2),rE(3)) < 250 && ...
     ~any(strcmp(sol2.qpStatus,'primalInfeasible')) && ...
     ~any(strcmp(sol2.qpStatus,'numericalFailure'));
if ok
    plan2 = plan;  plan2.sol = sol2;  plan2.opt = o;
    plan2.tiltN = o.tiltMaxNode;
else
    plan2 = plan;
end
end
