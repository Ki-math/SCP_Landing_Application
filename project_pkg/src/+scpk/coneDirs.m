function D = coneDirs(n,halfAngle)
%CONEDIRS  推力錐 ||T|| <= Gam を多面体近似する法線方向を返す.
%
%   D = CONEDIRS(N,HALFANGLE) は機体 x 軸を中心とする半頂角 HALFANGLE [rad] の
%   範囲を覆う N 個の方向を N x 3 で返す. ||T|| <= Gam を D*T <= kappa*Gam の
%   線形不等式で近似する.
%
%   球全体を等方に覆うと精度が出ない (N=49 で錐を 7.8%% 過大評価する).
%   ジンバルが +-15deg に制限されているので推力方向は狭い錐内に限られる.
%   その範囲だけを密に覆えば同じ本数でずっと高精度になる.
%
%   HALFANGLE 省略時は 25 deg (ジンバル 15deg に余裕を見た値).
if nargin < 2 || isempty(halfAngle), halfAngle = deg2rad(25); end
%% 中心軸 (+x) と, 半頂角までの同心リング
nRing = max(1, round(sqrt(n/3)));
perRing = max(3, floor((n-1)/nRing));
D = [1 0 0];
for i = 1:nRing
    a = halfAngle*i/nRing;
    for j = 0:perRing-1
        b = 2*pi*j/perRing + pi*i/nRing;   %% リングごとに位相をずらす
        D(end+1,:) = [cos(a), sin(a)*cos(b), sin(a)*sin(b)]; %#ok<AGROW>
    end
end
end
