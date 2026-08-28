function fp = mexFingerprint()
%MEXFINGERPRINT  生成MEXが依存する構造体レイアウトの指紋 (文字列).
%
%   FP = MEXFINGERPRINT() は cfg (scpk.model6) と pp (scpk.planParams) の
%   フィールド名リストを連結した文字列を返す. MATLAB Coder の生成MEXは
%   構造体のフィールド構成 (名前と順序) に厳密なので, この指紋が変わったら
%   codegenBuild / codegenPlanIter の再実行が必要.
%
%   See also SCPCHECKMEX, CODEGENBUILD, CODEGENPLANITER
cfg = scpk.model6();
opt = scpk.planOptions6();
opt.phase = 1;  opt.engSched = 1;  opt.tiltMaxNode = [0.1 0.1];
[pp, qpp] = scpk.planParams(opt, 1, 1, 1);
tp = scpk.trackParams(scpk.track6Options(), cfg);
fp = ['cfg:'  strjoin(fieldnames(cfg).', ',') ...
      '|pp:'  strjoin(fieldnames(pp).', ',') ...
      '|qpp:' strjoin(fieldnames(qpp).', ',') ...
      '|tp:'  strjoin(fieldnames(tp).', ',')];
end
