function plotClosedLoop(sol, cl, cfg, axs)
%PLOTCLOSEDLOOP  計画 vs 閉ループのトレンド比較 (計画タブと同じ粒度の8面図).
%
%   PLOTCLOSEDLOOP(SOL, CL, CFG)        新規Figureに描く
%   PLOTCLOSEDLOOP(SOL, CL, CFG, AXS)   AXS (8要素のaxes配列) に描く (GUI統合)
%
%   内容: 高度 / 水平位置(CR,DR) / 速度(全機速・鉛直) / 姿勢(傾斜角・角速度) /
%         推力(大きさ・点火基数) / TVC角 / 舵角偏差(4枚) / 追従QP計算時間
%   実線=閉ループ, 黒破線=計画.
%
%   See also PLOTPLANTREND, RUN_MAIN, SCPAPP
if nargin < 4 || isempty(axs)
    figure('Color','w','Position',[40 40 1300 780],'Name','着陸解析: 計画 vs 閉ループ');
    tl = tiledlayout(3,3,'Padding','compact','TileSpacing','compact');
    axs = gobjects(1,8);
    for i = 1:7, axs(i) = nexttile(tl); end
    axs(8) = nexttile(tl, [1 2]);
end
for i = 1:8, cla(axs(i),'reset');  hold(axs(i),'on');  grid(axs(i),'on'); end
N = numel(sol.phase);  tu = sol.t(1:N);
tiltOf = @(Q) arrayfun(@(k) acosd(max(-1,min(1,1-2*(Q(3,k)^2+Q(4,k)^2)))), 1:size(Q,2));

%% 閉ループの慣性系速度 (鉛直成分)
n = numel(cl.t);  vIc = zeros(3,n);
for k = 1:n
    q = cl.x(7:10,k)/norm(cl.x(7:10,k));
    vIc(:,k) = quat2dcm(q.').'*cl.x(4:6,k);
end
%% 計画の慣性系速度
vIp = zeros(3,N+1);
for k = 1:N+1
    q = sol.q(:,k)/norm(sol.q(:,k));
    vIp(:,k) = quat2dcm(q.').'*sol.v(:,k);
end

%% 1. 高度
plot(axs(1), sol.t, sol.r(1,:), 'k--', cl.t, cl.x(1,:), 'b-','LineWidth',1.4);
xlabel(axs(1),'t [s]'); ylabel(axs(1),'高度 [m]');
legend(axs(1),{'計画','閉ループ'},'Location','best');
title(axs(1),'高度 (以降も 破線=計画)');

%% 2. 水平位置
plot(axs(2), cl.t, cl.x(2,:), 'b-','LineWidth',1.4);
plot(axs(2), cl.t, cl.x(3,:), 'r-','LineWidth',1.4);
plot(axs(2), sol.t, sol.r(2,:), 'b--', sol.t, sol.r(3,:), 'r--','LineWidth',1.0);
xlabel(axs(2),'t [s]'); ylabel(axs(2),'位置 [m]');
legend(axs(2),{'クロスレンジ','ダウンレンジ'},'Location','best');
title(axs(2),'水平位置');

%% 3. 速度
plot(axs(3), cl.t, vecnorm(cl.x(4:6,:)), 'b-','LineWidth',1.4);
plot(axs(3), cl.t, vIc(1,:), 'r-','LineWidth',1.4);
plot(axs(3), sol.t, vecnorm(sol.v), 'b--', sol.t, vIp(1,:), 'r--','LineWidth',1.0);
xlabel(axs(3),'t [s]'); ylabel(axs(3),'速度 [m/s]');
legend(axs(3),{'|v|','鉛直 (上+)'},'Location','best');
title(axs(3),'速度');

%% 4. 姿勢 (左:傾斜 右:角速度)
yyaxis(axs(4),'left');
plot(axs(4), cl.t, tiltOf(cl.x(7:10,:)), 'b-','LineWidth',1.4);
plot(axs(4), sol.t, tiltOf(sol.q), 'b--','LineWidth',1.0);
ylabel(axs(4),'傾斜角 [deg]');
yyaxis(axs(4),'right');
plot(axs(4), cl.t, rad2deg(vecnorm(cl.x(11:13,:))), '-','Color',[.85 .4 .1],'LineWidth',1.2);
plot(axs(4), sol.t, rad2deg(vecnorm(sol.w)), '--','Color',[.85 .4 .1],'LineWidth',1.0);
ylabel(axs(4),'角速度 [deg/s]');
xlabel(axs(4),'t [s]'); title(axs(4),'姿勢 (左:傾斜 右:角速度)');

%% 5. 推力 (左:大きさ 右:点火基数)
yyaxis(axs(5),'left');
plot(axs(5), cl.t, vecnorm(cl.u(1:3,:))*cfg.Fs/1e6, 'b-','LineWidth',1.4);
stairs(axs(5), tu, sol.Tmag(1:N)/1e6, 'b--','LineWidth',1.0);
ylabel(axs(5),'推力 [MN]');
yyaxis(axs(5),'right');
stairs(axs(5), tu, sol.engSched(1:N), '-','Color',[.85 .4 .1],'LineWidth',1.2);
ylabel(axs(5),'点火基数 (計画)'); ylim(axs(5),[-0.2, max(sol.engSched)+0.8]);
xlabel(axs(5),'t [s]'); title(axs(5),'推力 (左:大きさ 右:基数)');

%% 6. TVC角
gimC = atan2d(hypot(cl.u(2,:), cl.u(3,:)), max(abs(cl.u(1,:)), 1e-9));
gimC(vecnorm(cl.u(1:3,:)) < 1e-6) = 0;             % 非点火は無効
gimP = atan2d(hypot(sol.uhat(2,1:N), sol.uhat(3,1:N)), max(abs(sol.uhat(1,1:N)),1e-9));
gimP(sol.engSched(1:N)==0) = 0;
plot(axs(6), cl.t, gimC, 'b-','LineWidth',1.4);
stairs(axs(6), tu, gimP, 'b--','LineWidth',1.0);
xlabel(axs(6),'t [s]'); ylabel(axs(6),'TVC角 [deg]');
title(axs(6),'TVC (推力偏向角. 非点火区間=0)');

%% 7. 舵角偏差 (4枚)
if cfg.surfMode == 2
    names = {'フィン1','フィン2','フィン3','フィン4'};
else
    names = {'フラップ前右','フラップ前左','フラップ後右','フラップ後左'};
end
cols = lines(4);  hh = gobjects(1,4);
for i = 1:4
    hh(i) = plot(axs(7), cl.t, rad2deg(cl.u(3+i,:)), '-','Color',cols(i,:),'LineWidth',1.2);
    stairs(axs(7), tu, rad2deg(sol.uhat(3+i,1:N)), '--','Color',cols(i,:),'LineWidth',0.8);
end
xlabel(axs(7),'t [s]'); ylabel(axs(7),'舵角偏差 [deg]');
legend(axs(7), hh, names, 'Location','best');
title(axs(7),'舵面 (トリムからの偏差)');

%% 8. 追従QPの計算時間
histogram(axs(8), cl.qpT*1e3, 30);
xlabel(axs(8),'追従QP時間 [ms]'); ylabel(axs(8),'回数');
title(axs(8), sprintf('MPC %d回 平均%.1fms 最大%.1fms 収束%.0f%%', numel(cl.qpT), ...
      mean(cl.qpT)*1e3, max(cl.qpT)*1e3, 100*mean(strcmp(cl.st,'converged'))));
end
