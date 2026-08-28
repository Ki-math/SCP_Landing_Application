function acc = acceptance(sol,cfg,opt)
%ACCEPTANCE  SCP 解の受け入れ判定.
%
%   ACC = ACCEPTANCE(SOL,CFG,OPT) は軌道解 SOL が採用に足るかを判定する.
%
%   QP が収束しても軌道が成立しているとは限らない. 判定は3つの層で行う.
%     1. 仮想制御の総量   線形化された動力学すら満たせていない = 真の実行不可能性
%     2. 終端スラック     目標に到達できていない量そのもの
%     3. 非線形再積分誤差 解いた制御列を真の非線形モデルに入れて伝播した差
%
%   3 が最も信頼できる独立指標なので主判定に据える. 1 はスケール後座標の総和で
%   物理量に直結しないため補助にとどめる (再積分誤差 0.9m の解と 48m の解で
%   仮想制御が同じ 0.058 だった実例がある).
%
%   ACC のフィールド
%     ok          採用可否
%     reason      不採用の理由 ('' なら採用)
%     reintErr    非線形再積分の最大位置誤差 [m]
%     termErr     終端条件の誤差 (位置 [m], 速度 [m/s], 姿勢 [deg])
%     virtCtrl    仮想制御の総量
%     solverOK    QP が全反復で正常ステータスだったか
%
%   See also SCPK.PLAN, SCPK.REPLAN, SCPK.VERIFY
if nargin < 3 || isempty(opt), opt = scpk.acceptanceOptions(); end
acc = struct('ok',false,'reason','','reintErr',inf,'termErr',[inf inf inf], ...
             'virtCtrl',inf,'solverOK',false);

%% --- 1. ソルバのステータス ---
if isfield(sol,'qpStatus')
    bad = ~all(strcmp(sol.qpStatus,'converged') | strcmp(sol.qpStatus,'maxIter'));
    acc.solverOK = ~bad;
    if bad
        k = find(~(strcmp(sol.qpStatus,'converged') | strcmp(sol.qpStatus,'maxIter')),1);
        acc.reason = sprintf('QP status: %s (SCP 反復 %d)', sol.qpStatus{k}, k);
        return
    end
else
    acc.solverOK = true;   %% 情報が無い場合は判定しない
end

%% --- 2. 仮想制御 ---
if isfield(sol,'virtCtrl'), acc.virtCtrl = sol.virtCtrl; else, acc.virtCtrl = 0; end
if acc.virtCtrl > opt.maxVirtCtrl
    acc.reason = sprintf('仮想制御が残存 (%.3e > %.3e)', acc.virtCtrl, opt.maxVirtCtrl);
    return
end

%% --- 3. 非線形再積分 (主判定) ---
ver = scpk.verify(sol,cfg);
acc.reintErr = ver.maxPosErr;
if acc.reintErr > opt.maxReintErr
    acc.reason = sprintf('再積分誤差が過大 (%.2f m > %.2f m)', acc.reintErr, opt.maxReintErr);
    return
end

%% --- 4. 終端条件 (真の軌道上で) ---
if isfield(opt,'target') && ~isempty(opt.target)
    t = opt.target;
    ePos = hypot(ver.term(1)-t(1), ver.term(2)-t(2));
    eVel = hypot(ver.term(3)-t(3), ver.term(4)-t(4));
    eAng = abs(rad2deg(ver.term(5)-t(5)));
    acc.termErr = [ePos eVel eAng];
    if ePos > opt.maxTermPos || eVel > opt.maxTermVel || eAng > opt.maxTermAng
        acc.reason = sprintf('終端誤差が過大 (位置%.1fm 速度%.2fm/s 姿勢%.1fdeg)', ePos, eVel, eAng);
        return
    end
end
acc.ok = true;
end
