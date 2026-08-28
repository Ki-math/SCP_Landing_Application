function ref = densify6(sol, cfg, dtRef)
%DENSIFY6  計画解をセグメント毎に RK4 再積分し, 追従用の密な参照を作る.
%
%   REF = DENSIFY6(SOL, CFG)        既定 0.1 s 刻みで再構成 (追従dt=0.2s向け)
%   REF = DENSIFY6(SOL, CFG, DTREF) 刻みを指定 [s] (track.dt を細かくした場合は
%                                   dtRef ~ track.dt/2 を目安に細かくする)
%   節点間隔 ~1 s の線形補間は 0.1 s スケールで力学不整合が大きく, 追従目標に
%   ならない. 参照時間軸は 0 始まり.
%
%   See also SCPK.TRACK6STEP, SCPK.REPLAN6
if nargin < 3, dtRef = 0.1; end
sc = cfg.sc;
tD = [];  xD = [];  uD = [];  eD = [];
for k = 1:numel(sol.t)-1
    t0 = sol.t(k);  t1 = sol.t(k+1);
    nSub = max(2, ceil((t1-t0)/dtRef));
    hs = (t1-t0)/nSub/sc.T;
    xk = sol.xhat(:,k);  uk = sol.uhat(:,k);
    for j = 0:nSub-1
        tD(end+1) = t0 + j*(t1-t0)/nSub; %#ok<AGROW>
        xD(:,end+1) = xk;  uD(:,end+1) = uk;  eD(end+1) = sol.engSched(k); %#ok<AGROW>
        k1=scpk.dynamics6(xk,uk,cfg); k2=scpk.dynamics6(xk+hs/2*k1,uk,cfg);
        k3=scpk.dynamics6(xk+hs/2*k2,uk,cfg); k4=scpk.dynamics6(xk+hs*k3,uk,cfg);
        xk = xk + hs/6*(k1+2*k2+2*k3+k4);
        xk(7:10) = xk(7:10)/norm(xk(7:10));
    end
end
tD(end+1) = sol.t(end);  xD(:,end+1) = sol.xhat(:,end);
uD(:,end+1) = sol.uhat(:,end);  eD(end+1) = sol.engSched(end);
ref = struct('t',tD - tD(1), 'xhat',xD, 'uhat',uD, 'engSched',eD);
end
