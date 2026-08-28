function plotMcsBirdseye(ax, res)
%PLOTMCSBIRDSEYE  MCS全ランの飛行軌道 鳥瞰図 (3D) を描く.
%
%   PLOTMCSBIRDSEYE(AX, RES)  RES = runMCS_scp の res 配列 (traj 付き)
%   成功ラン=青系, 失敗ラン=赤. パッドと接地点マーカー付き.
%
%   See also RUNMCS_SCP, SCPAPP
cla(ax);  hold(ax,'on');  grid(ax,'on');
xmax = 50;  ymax = 30;  zmax = 100;
for i = 1:numel(res)
    T = res(i).traj;                    % [高度; クロス; ダウンレンジ]
    if isempty(T), continue; end
    if res(i).ok, c = [0.25 0.45 0.85 0.5]; else, c = [0.85 0.30 0.20 0.6]; end
    plot3(ax, T(3,:), T(2,:), T(1,:), '-', 'Color', c, 'LineWidth', 1.0);
    plot3(ax, T(3,end), T(2,end), max(T(1,end),0), 'o', ...
          'MarkerSize',5, 'MarkerFaceColor',c(1:3), 'MarkerEdgeColor','none');
    xmax = max([xmax, abs(T(3,:))]);  ymax = max([ymax, abs(T(2,:))]);
    zmax = max([zmax, T(1,:)]);
end
th = linspace(0,2*pi,50);
plot3(ax, 25*cos(th), 25*sin(th), zeros(size(th)), '-', ...
      'Color',[0.1 0.5 0.3], 'LineWidth', 2);
patch(ax, 'XData',[-xmax xmax xmax -xmax], 'YData',[-ymax -ymax ymax ymax], ...
      'ZData',[0 0 0 0], 'FaceColor',[0.90 0.92 0.94], 'EdgeColor','none', ...
      'FaceAlpha',0.6);
xlabel(ax,'ダウンレンジ [m]');  ylabel(ax,'クロスレンジ [m]');  zlabel(ax,'高度 [m]');
view(ax, [-40 18]);  axis(ax, 'tight');
set(ax,'ZLim',[0 zmax*1.05]);
daspect(ax,[1 1 3]);                 % XY等スケール (パッドが円に見える), 高度1/3圧縮
end
