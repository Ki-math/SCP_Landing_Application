function prob = scpWindTune(prob)
%SCPWINDTUNE  強風向けの機体制約緩和レシピ (計画に風を織り込む場合とセットで使う).
%
%   PROB = SCPWINDTUNE(PROB)  windProf を設定した問題に適用する.
%
%   やること (falcon9 クロス風10 m/s級で 計画残差 22.8m -> 13.5m 実測.
%    細長体空力補正後の値. USER_GUIDE §6「強風時の注意」参照):
%     - 姿勢レート緩和      wMaxFlip>=15deg/s, wMaxTight>=8deg/s
%     - 傾斜スケジュール2倍  (精密着陸フェーズは据え置き)
%     - コースト中の風上リーン許可 (bellyHold=8. グリッドフィン機のみ:
%       高速降下中に機体を傾け空力側面力で風ドリフトを打ち消す)
%     - 追従MPCの姿勢重み強化 wQuat>=3.5, wRate>=3.0 (接地時の傾斜押さえ)
%
%   使い方:
%     prob = scpProblem('falcon9');
%     prob.windProf = loadWindProfile('config/wind_shear_example.json');
%     prob = scpWindTune(prob);
%     scpPlan(prob);  R = scpClosedLoop(prob, struct());
%
%   See also SCPPROBLEM, SCPPLAN, LOADWINDPROFILE
prob.opt.wMaxFlip  = max(prob.opt.wMaxFlip,  deg2rad(15));
prob.opt.wMaxTight = max(prob.opt.wMaxTight, deg2rad(8));
i4 = find(prob.phase == 4);
tN = prob.tiltN*2;  tN(i4(1):end) = prob.tiltN(i4(1):end);
prob.tiltN = tN;
if isfield(prob.opt,'tiltMax')
    prob.opt.tiltMax = max(prob.opt.tiltMax, deg2rad(12));
end
if prob.cfg.surfMode == 2
    prob.opt.bellyHold = 8;      % テールファースト機: コーストの姿勢箱を緩める
    if isfield(prob.opt,'wFlap')
        prob.opt.wFlap = 0;      % 風対抗のリーン保持には大きな定常フィントリム
    end                          % (~15deg) が必要なため舵面正則化は解除する
                                 % (0.1でも水平20->41mに悪化, 実測)
end                              % (ベリーフロップ機は姿勢保持が必須なので触らない)
prob.track.wQuat = max(prob.track.wQuat, 3.5);
prob.track.wRate = max(prob.track.wRate, 3.0);
end
