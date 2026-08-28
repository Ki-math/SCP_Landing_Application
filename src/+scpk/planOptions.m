function opt = planOptions()
%PLANOPTIONS  軌道計画SCP の既定設定 (許容誤差ベース).
%
%   追従MPC (TRACKOPTIONS) と同じ設計思想. 許容誤差で変数を無次元化し,
%   単純な上下限は箱制約に分離する. 相違点は目的関数で, 追従ではなく
%   燃料最小 + 終端条件の厳密ペナルティを使う.
opt.tol.pos   = 5;        %% [m]
opt.tol.vel   = 0.5;      %% [m/s]
opt.tol.ang   = 0.5;      %% [deg]
opt.tol.rate  = 2;        %% [deg/s]
opt.tol.mass  = 100;      %% [kg]
opt.tol.thr   = 20e3;     %% [N]
opt.tol.flap  = 0.05;

opt.wFuel   = 1;          %% 終端質量最大化 (スケール後座標)
opt.wTR     = 0.05;       %% 近接型トラストリージョン
opt.wCtrl   = 0.02;       %% 制御努力
opt.lamVC   = 1e4;        % 仮想制御 L1 (厳密ペナルティ). スケール後座標では nu の単位が
opt.lamTerm = 1e2;        % 終端条件 L1
opt.lamLC   = 1e2;        % ||T||=Gam 線形化スラックの L1
opt.reg     = 1e-2;       %% 全変数への一様正則化 (平坦方向を消す)

opt.tolBox  = [1; 5; 0.5; 0.5; 2; 2];   %% 終端許容箱 [m m m/s m/s deg deg/s]
opt.hMargin = 20;         %% 高度下限の余裕 [m]
opt.nCone   = 16;
opt.coneShrink = 0.98;
opt.maxIter = 6;          %% SCP 反復
opt.tolStep = 1e-2;       %% 収束判定 (スケール後座標のステップ幅)
opt.qp = scpk.qpOptions();
opt.qp.maxIter = 8000;
opt.qp.omega   = 1e1;
opt.verbose = false;
end

