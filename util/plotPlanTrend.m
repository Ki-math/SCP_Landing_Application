function plotPlanTrend(sol, cfg, axs)
%PLOTPLANTREND  計画解の主要状態量・操作量トレンド (6面図).
%
%   PLOTPLANTREND(SOL, CFG)        新規Figureに描く
%   PLOTPLANTREND(SOL, CFG, AXS)   AXS (6要素のaxes配列) に描く (GUI統合)
%
%   内容: 位置(高度・CR/DR) / 速度(全機速・鉛直) / 姿勢(傾斜角・角速度) /
%         推力(大きさ・点火基数) / TVC角 / 舵角偏差(4枚, 凡例つき)
%   縦の点線はフェーズ境界.
%
%   See also SCPPLAN, PLOTCLOSEDLOOP, SCPAPP
if nargin < 3 || isempty(axs)
    figure('Color','w','Position',[60 60 1200 700],'Name','計画トレンド');
    tl = tiledlayout(2,3,'Padding','compact','TileSpacing','compact');
    axs = gobjects(1,6);
    for i = 1:6, axs(i) = nexttile(tl); end
end
t = sol.t;  N = numel(sol.phase);  tu = t(1:N);
tPh = t([true, diff(sol.phase) ~= 0]);          % フェーズ開始時刻
for i = 1:6
    cla(axs(i),'reset');  hold(axs(i),'on');  grid(axs(i),'on');
end

%% 1. 位置 (左:高度 右:水平位置)
yyaxis(axs(1),'left');
plot(axs(1), t, sol.r(1,:), 'b-','LineWidth',1.4);  ylabel(axs(1),'高度 [m]');
yyaxis(axs(1),'right');
h1 = plot(axs(1), t, sol.r(2,:), '-','Color',[.85 .4 .1],'LineWidth',1.2);
h2 = plot(axs(1), t, sol.r(3,:), '--','Color',[.85 .4 .1],'LineWidth',1.2);
ylabel(axs(1),'水平位置 [m]');
addPh(axs(1), tPh);
xlabel(axs(1),'t [s]');
legend(axs(1), [h1 h2], {'クロスレンジ','ダウンレンジ'}, 'Location','best');
title(axs(1),'位置 (点線=フェーズ境界)');

%% 2. 速度 (全機速 + 鉛直成分)
vI = zeros(3,N+1);
for k = 1:N+1
    q = sol.q(:,k)/norm(sol.q(:,k));
    vI(:,k) = quat2dcm(q.').'*sol.v(:,k);        % 慣性系速度
end
plot(axs(2), t, vecnorm(sol.v), 'b-','LineWidth',1.4);
plot(axs(2), t, vI(1,:), 'r-','LineWidth',1.4);
addPh(axs(2), tPh);
xlabel(axs(2),'t [s]'); ylabel(axs(2),'速度 [m/s]');
legend(axs(2),{'|v|','鉛直 (上+)'},'Location','best'); title(axs(2),'速度');

%% 3. 姿勢 (左:傾斜のピッチ/ヨー成分 右:角速度)
[thP, thY] = tiltPY(sol.q);
yyaxis(axs(3),'left');
plot(axs(3), t, thP, 'b-','LineWidth',1.4);
plot(axs(3), t, thY, 'r-','LineWidth',1.4);
ylabel(axs(3),'傾斜角成分 [deg]');
yyaxis(axs(3),'right');
plot(axs(3), t, rad2deg(vecnorm(sol.w)), '-','Color',[.85 .4 .1],'LineWidth',1.0);
ylabel(axs(3),'角速度 [deg/s]');
addPh(axs(3), tPh);
xlabel(axs(3),'t [s]');
legend(axs(3),{'ピッチ (DR方向の倒れ)','ヨー (CR方向の倒れ)'},'Location','best');
title(axs(3),'姿勢 (左:傾斜成分 右:角速度)');

%% 4. 推力 (左:大きさ 右:点火基数)
yyaxis(axs(4),'left');
stairs(axs(4), tu, sol.Tmag(1:N)/1e6, 'b-','LineWidth',1.4);  ylabel(axs(4),'推力 [MN]');
yyaxis(axs(4),'right');
stairs(axs(4), tu, sol.engSched(1:N), '-','Color',[.85 .4 .1],'LineWidth',1.2);
ylabel(axs(4),'点火基数'); ylim(axs(4),[-0.2, max(sol.engSched)+0.8]);
addPh(axs(4), tPh);
xlabel(axs(4),'t [s]'); title(axs(4),'推力 (左:大きさ 右:基数)');

%% 5. TVC角 (ピッチ/ヨー成分, 符号付き)
[gP, gY] = tvcPY(sol.uhat(:,1:N), sol.engSched(1:N));
stairs(axs(5), tu, gP, 'b-','LineWidth',1.4);
stairs(axs(5), tu, gY, 'r-','LineWidth',1.4);
addPh(axs(5), tPh);
xlabel(axs(5),'t [s]'); ylabel(axs(5),'TVC角 [deg]');
legend(axs(5),{'ピッチ面 (T_3/T_1)','ヨー面 (T_2/T_1)'},'Location','best');
title(axs(5),'TVC (符号付き偏向角. 非点火区間=0)');

%% 6. 舵角偏差 (4枚, 凡例つき)
if cfg.surfMode == 2
    names = {'フィン1','フィン2','フィン3','フィン4'};
else
    names = {'フラップ前右','フラップ前左','フラップ後右','フラップ後左'};
end
cols = lines(4);  hh = gobjects(1,4);
for i = 1:4
    hh(i) = stairs(axs(6), tu, rad2deg(sol.uhat(3+i,1:N)), '-','Color',cols(i,:),'LineWidth',1.2);
end
addPh(axs(6), tPh);
xlabel(axs(6),'t [s]'); ylabel(axs(6),'舵角偏差 [deg]');
legend(axs(6), hh, names, 'Location','best');
title(axs(6),'舵面 (トリムからの偏差)');
end

function addPh(ax, tPh)
for tp = tPh(2:end), xline(ax, tp, 'k:'); end
end

function [thP, thY] = tiltPY(Q)
%TILTPY  傾斜のピッチ/ヨー成分 [deg]. 機体x軸の慣性系方向から分解:
%  ピッチ = ダウンレンジ(z)方向への倒れ, ヨー = クロスレンジ(y)方向への倒れ
n = size(Q,2);  thP = zeros(1,n);  thY = zeros(1,n);
for k = 1:n
    q0=Q(1,k); q1=Q(2,k); q2=Q(3,k); q3=Q(4,k);
    bx = [1-2*(q2*q2+q3*q3); 2*(q1*q2+q0*q3); 2*(q1*q3-q0*q2)];  % 機体x軸 (慣性系)
    thY(k) = atan2d(bx(2), bx(1));
    thP(k) = atan2d(bx(3), bx(1));
end
end

function [gP, gY] = tvcPY(U, eng)
%TVCPY  TVCの符号付き偏向角 [deg]. ピッチ面 = atan2(T3,T1), ヨー面 = atan2(T2,T1)
gP = atan2d(U(3,:), max(abs(U(1,:)), 1e-9));
gY = atan2d(U(2,:), max(abs(U(1,:)), 1e-9));
gP(eng==0) = 0;  gY(eng==0) = 0;
end
