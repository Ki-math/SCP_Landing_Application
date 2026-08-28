function s = touchdownStats(src, cfg)
%TOUCHDOWNSTATS  接地状態の要約 (計画解 or 閉ループ終端状態から).
%
%   S = TOUCHDOWNSTATS(SOL, CFG)    計画解 (終端ノード) から
%   S = TOUCHDOWNSTATS(XEND, CFG)   閉ループの物理状態ベクトル (14x1) から
%
%   S のフィールド:
%     horiz / cr / dr   接地位置: 水平誤差, クロスレンジ, ダウンレンジ [m]
%     vz                鉛直速度 (慣性系, 上+) [m/s]
%     vh                水平速度 [m/s]
%     tilt              傾斜角 [deg]
%     wDeg              角速度ノルム [deg/s]
%     fuel              残推進薬 [t]
%
%   See also SCPPLAN, SCPCLOSEDLOOP, SCPAPP
if isstruct(src)
    r = src.r(:,end);  vB = src.v(:,end);  q = src.q(:,end);
    w = src.w(:,end);  mass = src.m(end);
else
    x = src;
    r = x(1:3);  vB = x(4:6);  q = x(7:10);  w = x(11:13);  mass = x(14);
end
q = q/norm(q);
R = quat2dcm(q.');
vI = R.'*vB;
s.cr = r(2);  s.dr = r(3);  s.horiz = hypot(r(2), r(3));
s.vz = vI(1);
s.vh = hypot(vI(2), vI(3));
s.tilt = acosd(max(-1, min(1, 1-2*(q(3)^2+q(4)^2))));
s.wDeg = rad2deg(norm(w));
s.fuel = (mass - cfg.veh.dryMass)/1e3;
end
