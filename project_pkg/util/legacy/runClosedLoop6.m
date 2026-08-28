function out = runClosedLoop6()
%RUNCLOSEDLOOP6  6自由度 閉ループ着陸シミュレーション (追従MPC 100 ms).
%
%   プラント: scpk.dynamics6 を RK4 10 ms で積分 (真値モデル).
%   外乱    : 初期位置 +[15;10;-20] m, 初期速度 +[1;-1;1.5] m/s (機体系),
%             推力効率 0.97 (モデル誤差), 定常風加速度 0.3 m/s^2 (クロス).
%   制御    : 100 ms ごとに scpk.track6Step (LTV-MPC, PIPG, ウォームスタート).
%   比較    : 同じ外乱でオープンループ (参照制御をそのまま印加).
%
%   結果は drivers/results/closedloop.mat に保存.
%
%   See also SCPK.TRACK6STEP, SCPK.PLAN6FT
here = fileparts(mfilename('fullpath'));  proj = fileparts(fileparts(here));
addpath(fullfile(proj,'src'), fullfile(proj,'src','cpp'));   % cpp: 手書きC++ソルバ (あれば使用)
S = load(fullfile(proj,'results','landing_vert.mat'));
ref = S.sol;  cfg = S.cfg;  sc = cfg.sc;
sx = [repmat(sc.L,3,1); repmat(sc.V,3,1); ones(4,1); repmat(1/sc.T,3,1); cfg.m0];

%% --- 参照の高密度化 (各セグメント内を RK4 で 0.05 s 刻みに再構成) ---
%% 節点間隔 ~1.2 s の線形補間は 0.1 s スケールで力学不整合が大きく, 追従目標
%% として不適 (MPC が補間誤差を追いかける). セグメント先頭の計画節点から
%% 計画制御 (区分一定) で積分し, 力学的に整合した密な参照を作る.
tD = [];  xD = [];  uD = [];  eD = [];
for k = 1:numel(ref.t)-1
    t0 = ref.t(k);  t1 = ref.t(k+1);
    nSub = max(2, ceil((t1-t0)/0.05));
    hs = (t1-t0)/nSub/sc.T;
    xk = ref.xhat(:,k);  uk = ref.uhat(:,k);
    for j = 0:nSub-1
        tD(end+1) = t0 + j*(t1-t0)/nSub; %#ok<AGROW>
        xD(:,end+1) = xk;  uD(:,end+1) = uk;  eD(end+1) = ref.engSched(k); %#ok<AGROW>
        k1=scpk.dynamics6(xk,uk,cfg); k2=scpk.dynamics6(xk+hs/2*k1,uk,cfg);
        k3=scpk.dynamics6(xk+hs/2*k2,uk,cfg); k4=scpk.dynamics6(xk+hs*k3,uk,cfg);
        xk = xk + hs/6*(k1+2*k2+2*k3+k4);
        xk(7:10) = xk(7:10)/norm(xk(7:10));
    end
end
tD(end+1) = ref.t(end);  xD(:,end+1) = ref.xhat(:,end);
uD(:,end+1) = ref.uhat(:,end);  eD(end+1) = ref.engSched(end);
ref.t = tD;  ref.xhat = xD;  ref.uhat = uD;  ref.engSched = eD;

%% --- 外乱設定 ---
dr0 = [15;10;-20];  dvB0 = [1;-1;1.5];   % 初期オフセット (物理)
thrEff = 0.97;                            % 推力効率 (プラント側)
aWind = [0; 0.3; 0]/sc.A;                 % 慣性系 風加速度 (無次元)

x0 = S.x0;  x0(1:3) = x0(1:3) + dr0;  x0(4:6) = x0(4:6) + dvB0;
tEnd = ref.t(end) + 6;  dtP = 0.01;  dtC = 0.1;  hP = dtP/sc.T;

topt = scpk.track6Options();
plant = @(x,u) plantDyn(x,u,cfg,thrEff,aWind);

for mode = 1:2   % 1=閉ループ, 2=オープンループ
    x = x0./sx;  t = 0;  z0 = [];  u = zeros(7,1);
    log.t=[]; log.x=[]; log.u=[]; log.qpT=[]; log.qpIt=[]; log.st={};
    nStep = round(tEnd/dtP);
    for s = 0:nStep-1
        if mod(s, round(dtC/dtP)) == 0
            if mode == 1
                [u,dbg,z0] = scpk.track6Step(x.*sx, t, ref, cfg, topt, z0);
                log.qpT(end+1)=dbg.qpTime; log.qpIt(end+1)=dbg.iters; log.st{end+1}=dbg.status;
            else
                tu = ref.t(1:size(ref.uhat,2));
                u = interp1(tu, ref.uhat.', min(t,tu(end)), 'previous', 'extrap').';
                eng0 = interp1(tu, ref.engSched(:), min(t,tu(end)), 'previous', 'extrap');
                if eng0 == 0, u(1:3) = 0; end
            end
        end
        k1=plant(x,u); k2=plant(x+hP/2*k1,u); k3=plant(x+hP/2*k2,u); k4=plant(x+hP*k3,u);
        x = x + hP/6*(k1+2*k2+2*k3+k4);
        x(7:10) = x(7:10)/norm(x(7:10));
        t = t + dtP;
        if mod(s,10)==0, log.t(end+1)=t; log.x(:,end+1)=x.*sx; log.u(:,end+1)=u; end
        if x(1)*sc.L <= 31, break; end          % 脚接地
    end
    res(mode).log = log;  res(mode).xEnd = x.*sx;  res(mode).tEnd = t; %#ok<AGROW>
end

%% --- 集計 ---
names = {'閉ループ','オープンループ'};
fprintf('\n%-14s %8s %10s %10s %8s %8s\n','mode','接地t[s]','水平[m]','鉛直v[m/s]','|v|[m/s]','傾斜[deg]');
for m = 1:2
    xE = res(m).xEnd;  q = xE(7:10)/norm(xE(7:10));
    Re = quat2dcm(q.');  rdI = Re.'*xE(4:6);
    tilt = acosd(max(-1,min(1,1-2*(q(3)^2+q(4)^2))));
    fprintf('%-14s %8.1f %10.2f %10.2f %8.2f %8.2f\n', names{m}, res(m).tEnd, ...
        hypot(xE(2),xE(3)), rdI(1), norm(rdI), tilt);
    res(m).horiz = hypot(xE(2),xE(3));  res(m).vI = rdI;  res(m).tilt = tilt;
end
cl = res(1).log;
fprintf('\nMPC: %d回, QP時間 平均%.1fms / 最大%.1fms, 収束率 %.0f%%\n', numel(cl.qpT), ...
    mean(cl.qpT)*1e3, max(cl.qpT)*1e3, 100*mean(strcmp(cl.st,'converged')));

out = struct('res',res,'ref',ref,'topt',topt,'dr0',dr0,'dvB0',dvB0,'thrEff',thrEff);
save(fullfile(proj,'results','closedloop.mat'),'-struct','out');
fprintf('保存: drivers/results/closedloop.mat\n');
end


function f = plantDyn(x,u,cfg,thrEff,aWind)
%PLANTDYN  真値プラント: 推力効率とモデル外乱 (風) を加えた dynamics6.
up = u;  up(1:3) = thrEff*u(1:3);
f = scpk.dynamics6(x, up, cfg);
%% 風: 慣性系加速度を機体系に変換して速度微分へ加える
q = x(7:10);  q0=q(1); q1=q(2); q2=q(3); q3=q(4);
R = [1-2*(q2*q2+q3*q3),   2*(q1*q2+q0*q3),   2*(q1*q3-q0*q2);
       2*(q1*q2-q0*q3), 1-2*(q1*q1+q3*q3),   2*(q2*q3+q0*q1);
       2*(q1*q3+q0*q2),   2*(q2*q3-q0*q1), 1-2*(q1*q1+q2*q2)];
f(4:6) = f(4:6) + R*aWind;
end
