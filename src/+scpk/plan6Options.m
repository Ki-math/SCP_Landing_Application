function opt = plan6Options()
%PLAN6OPTIONS  6自由度 動力降下フェーズの軌道計画 SCP の既定設定.
%
%   転回と減速を一体で最適化する. 遷移高度でのベリーフロップ姿勢から接地まで
%   を1つの問題として解き, 区間を事前に切らない (転回中に減速も進むため,
%   配分は最適化に任せるのが素直).
%
%   許容誤差で変数を無次元化する. 重み Q = 1/tol^2 で表現すると Hessian に
%   何桁もの開きが生じ, 一次法が収束しない (平面モデルで cond(P)=6e11 まで
%   悪化した実績がある).
opt.N = 20;                 %% 節点数

%% --- 許容誤差 (1単位ずれたら同じくらい困る量) ---
opt.tol.pos   = 5;          %% [m]
opt.tol.vel   = 0.5;        %% [m/s]
opt.tol.quat  = 0.005;      %% 四元数成分 (約 0.57 deg)
opt.tol.rate  = deg2rad(2); %% [rad/s]
opt.tol.mass  = 100;        %% [kg]
opt.tol.thr   = 20e3;       %% [N]
opt.tol.flap  = deg2rad(2); %% [rad]

%% --- 目的とペナルティ ---
opt.wFuel   = 1;            %% 終端質量最大化
opt.wTR     = 0.05;         %% 近接型トラストリージョン
opt.wCtrl   = 0.02;         %% 制御努力
opt.lamVC   = 1e4;          %% 仮想制御 L1 (厳密ペナルティ).
                            %% スケール後座標では nu の単位が変わるため 1e2 では
                            %% 不足する (平面モデルで再積分誤差 58m -> 0.65m の差)
opt.lamTerm = 1e2;          %% 終端条件 L1
opt.reg     = 1e-2;         %% 全変数への一様正則化 (平坦方向を消す).
                            %% 1e-6 だと前処理の列スケーリングが平坦方向を増幅する

%% --- 終端条件 ---
opt.termPos  = [31; 0; 0];          %% [高度; クロスレンジ; ダウンレンジ] [m]
opt.termVel  = [-1; 0; 0];          %% 慣性系速度 [m/s]
opt.termQuat = [1; 0; 0; 0];        %% 垂直姿勢
opt.termRate = [0; 0; 0];
opt.tolBox   = [5; 5; 5; 0.5; 0.5; 0.5; 0.02; 0.02; 0.02; ...
                deg2rad(2); deg2rad(2); deg2rad(2)];   %% 終端許容箱

%% --- 制約 ---
opt.nCone      = 12;        %% 推力錐の多角形近似
opt.coneShrink = 0.98;
opt.hMargin    = 20;        %% 高度下限の余裕 [m]
opt.glideSlope = deg2rad(80);  %% グライドスロープ (接地点への進入角制限)
opt.tiltMax    = deg2rad(95);  %% 最大傾斜 (ベリーフロップ 90deg を許容)

%% --- SCP ---
opt.maxIter  = 8;
opt.tolStep  = 1e-2;
opt.qp = scpk.qpOptions();
opt.qp.maxIter = 8000;
opt.qp.omega   = 1e1;
opt.verbose = false;
end
