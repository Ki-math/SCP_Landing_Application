function opt = trackOptions()
%TRACKOPTIONS  追従MPC の既定設定 (許容誤差ベース).
%
%   重みではなく「許容誤差」で問題を記述する. 各量を許容誤差で割った座標で
%   最適化するので, 追従コストは単純な二乗和になり P はほぼ単位行列になる.
%   重み側で許容誤差を表現する (Q = 1/tol^2) と P に何桁もの開きが生じ,
%   一次法が収束しない.
%
%   tol.*   1単位ずれたら同じくらい困る量 (物理単位)
%   w.*     その上での相対的な優先度. 既定は全て 1 で, 調整はほぼ不要
opt.Nm   = 8;        %% 水平の節点数
opt.dtm  = 0.20;     %% 節点間隔 [s]

opt.tol.pos   = 5;        %% [m]
opt.tol.vel   = 0.5;      %% [m/s]
opt.tol.ang   = 0.5;      %% [deg]
opt.tol.rate  = 2;        %% [deg/s]
opt.tol.mass  = 100;      %% [kg]
opt.tol.thr   = 20e3;     %% [N]
opt.tol.flap  = 0.05;     %% 差動 (-1..1) の許容

opt.w.pos   = 1;
opt.w.vel   = 1;
opt.w.ang   = 1;
opt.w.rate  = 0.3;
opt.w.mass  = 1e-2;   % 質量は追従対象ではないが, 平坦方向を消すため小さく入れる
opt.w.ctrl  = 0.1;        %% 参照制御からの逸脱
opt.w.term  = 3;          %% 終端の倍率

opt.lamVC = 1e2;     %% 動力学スラック (スケール後座標での L1)
%% 正則化. 全変数に一様に入れて平坦方向を消す. 1e-6 だと質量方向が平坦になり
%% 前処理の列スケーリングがそこを増幅して cond(P) が 2e8 に悪化する.
opt.reg   = 1e-2;
opt.hMargin = 20;    % 高度下限の余裕 [m]
opt.nCone = 12;      %% 推力錐の多角形近似
opt.coneShrink = 0.98;
opt.scpIter = 2;     %% 線形化点の更新回数
opt.maxVirtCtrl = 0.5;   % 仮想制御の許容. 超えたらフォールバック
opt.qp = scpk.qpOptions();
opt.qp.maxIter = 3000;
opt.qp.omega   = 1e2;
end


