function v = ovget(ov, name, def)
%OVGET  派生量オーバーライドの取得: ov.(name) が数値で NaN でなければそれ, 無ければ既定.
%
%   V = OVGET(OV, NAME, DEF)   機体モデル (model6 / modelFalcon9) の派生量
%   指定に使う. NaN 指定は「自動計算」の意味.
%
%   See also SCPK.MODEL6, SCPK.MODELFALCON9
if isstruct(ov) && isfield(ov,name) && ~isempty(ov.(name)) && all(~isnan(ov.(name)(:)))
    v = ov.(name);
else
    v = def;
end
end
