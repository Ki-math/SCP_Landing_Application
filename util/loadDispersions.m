function spec = loadDispersions(src)
%LOADDISPERSIONS  MCS変動パラメータ定義を読み込む (.m 関数 / .json 両対応).
%
%   SPEC = LOADDISPERSIONS('dispersions_starship')       config/ の .m 関数
%   SPEC = LOADDISPERSIONS('...\dispersions_xxx.json')   JSONファイル
%   SPEC = LOADDISPERSIONS(spec)                         cell {name,dist,p1,p2} をそのまま通す
%                                                        (GUIの表編集など)
%
%   JSON形式 (配列):
%     [ {"name":"thrEff","dist":"uniform","p1":0.95,"p2":1.00},
%       {"name":"windY","dist":"normal","p1":0.0,"p2":0.4}, ... ]
%
%   返り値 SPEC は {name, dist, p1, p2} の cell 配列 (runMCS_scp 互換).
%
%   See also RUNMCS_SCP
if iscell(src)
    assert(size(src,2) == 4, '変動定義cellは {名前,分布,p1,p2} の n×4 が必要です');
    spec = src;
elseif endsWith(src, '.json')
    raw = jsondecode(fileread(src));
    n = numel(raw);
    spec = cell(n,4);
    for i = 1:n
        if iscell(raw), r = raw{i}; else, r = raw(i); end
        spec{i,1} = r.name;  spec{i,2} = r.dist;
        spec{i,3} = r.p1;    spec{i,4} = r.p2;
    end
else
    spec = feval(src);
end
end
