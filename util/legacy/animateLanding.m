function animateLanding(sol, cfg, opt)
%ANIMATELANDING  6自由度 着陸計画解の3Dアニメーション (フリップ&着陸).
%
%   ANIMATELANDING(SOL,CFG)          MATLAB図で再生
%   ANIMATELANDING(SOL,CFG,struct('saveGif',true,'gifFile','x.gif'))
%
%   座標: 慣性 = [高度; クロスレンジ; ダウンレンジ]. 描画は X=ダウンレンジ,
%         Y=クロスレンジ, Z=高度. 姿勢は四元数 sol.q (R=慣性->機体) から機首軸を復元.
%
%   See also SCPK.PLAN6FT
if nargin < 3, opt = struct(); end
gv = @(f,d) getfield_(opt,f,d);
fps   = gv('fps',30);  playT = gv('playTime',10);  vscale = gv('vehScale',3);
saveG = gv('saveGif',false);  gifF = gv('gifFile','landing.gif');

t   = sol.t(:).';  N1 = numel(t);
Rp  = sol.r;                       % 3 x N1  [alt;cross;down]
Q   = sol.q;                       % 4 x N1
% 描画用に等時間サンプリング
nF  = max(2, round(playT*fps));
tt  = linspace(t(1), t(end), nF);
rx  = interp1(t, Rp(3,:), tt);     % down -> X
ry  = interp1(t, Rp(2,:), tt);     % cross-> Y
rz  = interp1(t, Rp(1,:), tt);     % alt  -> Z
qq  = zeros(4,nF);
for i=1:4, qq(i,:) = interp1(t, Q(i,:), tt); end

Lb = 62*vscale;                    % 見やすさのため機体を拡大
% ---- 図 ----
fig = figure('Color','w','Position',[80 60 1150 760],'Name','Starship フリップ&着陸 (6-DoF SCP)');
ax  = axes('Parent',fig); hold(ax,'on'); grid(ax,'on'); box(ax,'on');
xlabel(ax,'ダウンレンジ [m]'); ylabel(ax,'クロスレンジ [m]'); zlabel(ax,'高度 [m]');
xr = [min(rx)-100, max(rx)+100];  zr = [0, max(rz)+80];
axis(ax,'equal'); set(ax,'XLim',xr,'YLim',[-120 120],'ZLim',zr);
view(ax,[-40 16]); camproj(ax,'perspective');
title(ax,'6自由度 SCP 着陸軌道');
% 地面・パッド
patch(ax,'XData',[xr(1) xr(2) xr(2) xr(1)],'YData',[-120 -120 120 120],'ZData',[0 0 0 0], ...
      'FaceColor',[0.90 0.92 0.94],'EdgeColor','none');
th=linspace(0,2*pi,50); plot3(ax,25*cos(th),25*sin(th),zeros(size(th)),'g-','LineWidth',2);
% 全体軌道 (色: 高度)
plot3(ax, rx, ry, rz, '-', 'Color',[0.7 0.75 0.8], 'LineWidth',1.5);
hTrail = plot3(ax,NaN,NaN,NaN,'-','Color',[0.85 0.35 0.19],'LineWidth',2.5);
hBody  = plot3(ax,NaN,NaN,NaN,'-','Color',[0.15 0.2 0.28],'LineWidth',7);
hNose  = plot3(ax,NaN,NaN,NaN,'.','Color',[0.9 0.2 0.2],'MarkerSize',22);
hThr   = plot3(ax,NaN,NaN,NaN,'-','Color',[1 0.55 0],'LineWidth',3);
hTxt   = text(ax,xr(1)+20,0,zr(2)-20,'','FontSize',11,'FontName','Yu Gothic UI','BackgroundColor','w');

for k = 1:nF
    q = qq(:,k)/norm(qq(:,k)); q0=q(1);q1=q(2);q2=q(3);q3=q(4);
    R = [1-2*(q2^2+q3^2), 2*(q1*q2+q0*q3), 2*(q1*q3-q0*q2);
         2*(q1*q2-q0*q3), 1-2*(q1^2+q3^2), 2*(q2*q3+q0*q1);
         2*(q1*q3+q0*q2), 2*(q2*q3-q0*q1), 1-2*(q1^2+q2^2)];  % 慣性->機体
    noseI = R.'*[1;0;0];                       % 機首方向(機体+x)を慣性系へ
    c = [rx(k); ry(k); rz(k)];                 % 中心 (描画座標)
    nD = [noseI(3); noseI(2); noseI(1)];       % [alt;cross;down] -> [X;Y;Z]
    tail = c - (Lb/2)*nD;  tip = c + (Lb/2)*nD;
    set(hBody,'XData',[tail(1) tip(1)],'YData',[tail(2) tip(2)],'ZData',[tail(3) tip(3)]);
    set(hNose,'XData',tip(1),'YData',tip(2),'ZData',tip(3));
    % 推力プルーム (機体-x側の尾部から, 高度がある間のみ簡易表示)
    plume = tail - (Lb*0.5)*nD;
    if rz(k) > 1
        set(hThr,'XData',[tail(1) plume(1)],'YData',[tail(2) plume(2)],'ZData',[tail(3) plume(3)]);
    else
        set(hThr,'XData',NaN,'YData',NaN,'ZData',NaN);
    end
    set(hTrail,'XData',rx(1:k),'YData',ry(1:k),'ZData',rz(1:k));
    tilt = acosd(max(-1,min(1,1-2*(q2^2+q3^2))));
    set(hTxt,'String',sprintf(' t=%.1fs  高度=%.0fm  傾斜=%.0f°', tt(k), rz(k), tilt));
    drawnow;
    if saveG
        fr=getframe(fig); [A,map]=rgb2ind(frame2im(fr),256);
        if k==1, imwrite(A,map,gifF,'gif','LoopCount',inf,'DelayTime',1/fps);
        else, imwrite(A,map,gifF,'gif','WriteMode','append','DelayTime',1/fps); end
    end
end
end

function v = getfield_(s,f,d), if isfield(s,f), v=s.(f); else, v=d; end, end
