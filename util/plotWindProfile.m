function plotWindProfile(ax, wp)
%PLOTWINDPROFILE  風況プロファイルの可視化 (風速 vs 高度).
%
%   PLOTWINDPROFILE(WP)      新規Figureに描画. WP は loadWindProfile の出力
%                            (struct('h',...,'wy',...,'wz',...))
%   PLOTWINDPROFILE(AX, WP)  既存の座標軸 AX に描画 (GUI統合用)
%
%   例:
%     prob.windProf = loadWindProfile('config/wind_shear_example.json');
%     plotWindProfile(prob.windProf)
%
%   See also LOADWINDPROFILE, SCPAPP
if nargin < 2                             % plotWindProfile(wp) 形式
    wp = ax;
    ax = axes(figure('Color','w','Name','風況プロファイル'));
end
cla(ax, 'reset');                 % 前回の手動軸設定も含めて初期化 (自動スケールに戻す)
if isempty(wp)
    text(ax, 0.5, 0.5, '風プロファイル未設定 (無風)', ...
        'Units','normalized', 'HorizontalAlignment','center', 'Color',[.4 .4 .4]);
    return;
end
hFine = linspace(wp.h(1), wp.h(end), 200);
plot(ax, interp1(wp.h, wp.wy, hFine), hFine, 'b-', 'LineWidth', 1.5); hold(ax,'on');
plot(ax, interp1(wp.h, wp.wz, hFine), hFine, 'r-', 'LineWidth', 1.5);
plot(ax, wp.wy, wp.h, 'bo', 'MarkerSize', 4, 'MarkerFaceColor','b');
plot(ax, wp.wz, wp.h, 'ro', 'MarkerSize', 4, 'MarkerFaceColor','r');
xline(ax, 0, 'k:');
hold(ax,'off');  grid(ax,'on');
wAll = [wp.wy; wp.wz; 0];
pad = 0.08*max(max(wAll)-min(wAll), 1);
xlim(ax, [min(wAll)-pad, max(wAll)+pad]);
ylim(ax, [min(0, wp.h(1)), wp.h(end)]);
xlabel(ax, '風速 [m/s]');  ylabel(ax, '高度 (パッド基準) [m]');
legend(ax, {'クロスレンジ風 wy','ダウンレンジ風 wz'}, 'Location','best');
title(ax, '風況プロファイル');
end
