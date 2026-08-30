function prob = scpSetNodes(prob, factor)
%SCPSETNODES  計画のノード分割数をフェーズ毎に factor 倍へ変更する.
%
%   PROB = SCPSETNODES(PROB, FACTOR)
%
%   prob.phase / prob.eng / prob.tiltN を整合したまま再構成する
%   (フェーズ毎の最低ノード数4. 傾斜スケジュールはフェーズ内線形補間).
%   フェーズ時間 (sig0/sigMin/sigMax) はノード数と独立なので変更しない.
%
%   ノード数のトレードオフ:
%     増やす -> 離散化が細かく制約の見張りが密になるが, QP規模がほぼ比例して
%               増え計画・再計画が遅くなる (生成コードの上限 N<=200)
%     減らす -> 高速化するが, 粗い離散化はノード間の制約すり抜けと
%               追従参照の粗さを招く
%
%   例: prob = scpSetNodes(scpProblem('falcon9'), 1.5);   % 40 -> 60ノード
%
%   See also SCPPROBLEM, SCPPLAN
ph = prob.phase;  eng = prob.eng;  tN = prob.tiltN;
nPh = max(ph);
newPh = [];  newEng = [];  newTN = [];
for j = 1:nPh
    idx = find(ph == j);
    nj = numel(idx);
    mj = max(4, round(nj*factor));
    newPh  = [newPh,  j*ones(1,mj)];                     %#ok<AGROW>
    newEng = [newEng, eng(idx(1))*ones(1,mj)];           %#ok<AGROW>
    %% 傾斜スケジュール: フェーズ区間 (nj+1節点) を mj+1 節点へ線形補間.
    %% フェーズ境界節点は後のフェーズの値で上書き (テンプレートの構成規則と同じ)
    tSeg = tN(idx(1):idx(end)+1);
    tNew = interp1(linspace(0,1,nj+1), tSeg, linspace(0,1,mj+1));
    if isempty(newTN), newTN = tNew;
    else,              newTN = [newTN(1:end-1), tNew];   %#ok<AGROW>
    end
end
assert(numel(newPh)+1 == numel(newTN), 'tiltN 再構成の不整合');
assert(numel(newPh) <= 200, 'ノード数 %d が生成コードの上限200を超えます', numel(newPh));
prob.phase = newPh;
prob.eng   = newEng;
prob.tiltN = newTN;
end
