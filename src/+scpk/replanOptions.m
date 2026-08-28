function opt = replanOptions()
%REPLANOPTIONS  周期再計画の既定設定.
%
%   period      再計画の周期 [s]
%   tMin        残り時間がこれ未満なら再計画しない [s]
%   dtNode      計画の節点間隔 [s] (節点数は残り時間から決まる)
%   ladder      continuation の節点数段階 (最終節点数に対する比)
%   tFlipEnd    フリップ完了の想定時刻 [s] (基数切替の基準)
%   maxReintErr 非線形再積分誤差の許容 [m]. 超えたら計画を採用しない
opt.period      = 1.5;
opt.tMin        = 1.0;
opt.dtNode      = 0.28;
opt.Nmin        = 8;
opt.Nmax        = 25;
opt.ladder      = [0.5 1.0];
opt.tFlipEnd    = 5.0;
opt.yTarget     = 0;
opt.vTouch      = -1;
opt.warmStart   = true;
opt.maxReintErr = 5.0;
opt.plan        = scpk.planOptions();
opt.plan.maxIter = 6;
end
