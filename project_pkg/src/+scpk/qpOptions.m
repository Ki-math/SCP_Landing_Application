function opt = qpOptions()
%QPOPTIONS  SCPK.SOLVEQP の既定設定.
%
%   maxIter     最大反復数. 組み込みでは fixedIter=true と併用して固定する
%   fixedIter   true なら早期終了せず maxIter 回まわす (実行時間が決定的)
%   tolPri      主残差の許容 (相対)
%   tolDua      双対残差の許容 (相対)
%   omega       比例ゲインと積分ゲインの比. 問題のスケールに依存
%   rho         外挿係数 (1.5-1.9 が標準)
%   checkEvery  判定の間隔. 毎回だと余計な行列積が入る
%   powerIter   ステップ幅推定のべき乗法反復数
%   alpha/beta  事前計算したステップ幅. 与えるとべき乗法を回さない
%   certAfter   実行不可能性判定を始める反復数 (初期の暴れを避ける)
%   certTol     証明書の有意性しきい値
%   certEps     証明書の直交性しきい値
opt.maxIter    = 4000;
opt.fixedIter  = false;
opt.tolPri     = 1e-6;
opt.tolDua     = 1e-6;
opt.omega      = 1e2;
opt.rho        = 1.7;
opt.checkEvery = 25;
opt.powerIter  = 30;
opt.alpha      = [];
opt.beta       = [];
opt.certAfter  = 200;
opt.certTol    = 1e-8;
opt.certEps    = 1e-4;
end
