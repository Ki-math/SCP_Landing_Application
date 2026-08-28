function wp = loadWindProfile(src)
%LOADWINDPROFILE  風況プロファイルの読み込み/正規化.
%
%   WP = LOADWINDPROFILE(SRC)
%   SRC: .json パス (フィールド h, wy, wz の配列) か, 同フィールドの struct.
%
%   書式 (JSON例):
%     { "h":  [0, 200, 500, 1000, 2000],     高度 (着陸パッド基準) [m]
%       "wy": [3, 5, 8, 10, 12],             クロスレンジ方向の風速 [m/s]
%       "wz": [0, 0, -2, -4, -5] }           ダウンレンジ方向の風速 [m/s]
%
%   高度は昇順に並べ替えられる. プロファイル範囲外の高度は端の値でクランプ.
%   プラントの空力は対気相対速度 v - w で評価される (dynamics6 の wB).
%
%   使い方:
%     prob.windProf = loadWindProfile('config/wind_shear_example.json');
%     R = scpClosedLoop(prob, struct());
%
%   See also SCPCLOSEDLOOP, SCPMCS, PLOTWINDPROFILE, RUNCLOSEDLOOPREPLAN
if ischar(src) || isstring(src)
    wp = jsondecode(fileread(char(src)));
else
    wp = src;
end
assert(isfield(wp,'h') && isfield(wp,'wy') && isfield(wp,'wz'), ...
    'windProf は h / wy / wz フィールドが必要です');
h = wp.h(:);  wy = wp.wy(:);  wz = wp.wz(:);
assert(numel(h) == numel(wy) && numel(h) == numel(wz), ...
    'h / wy / wz は同じ長さが必要です');
assert(numel(h) >= 2, '高度点は2点以上必要です');
[h, iSort] = sort(h);
assert(all(diff(h) > 0), '高度 h に重複があります');
wp = struct('h', h, 'wy', wy(iSort), 'wz', wz(iSort));
end
