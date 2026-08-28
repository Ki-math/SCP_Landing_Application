function animateFalcon9(P, cfg, opt)
%ANIMATEFALCON9  Falcon9級ブースタの着陸アニメーション (展開式ランディングギア付き).
%
%   ANIMATEFALCON9(P, CFG, OPT)
%   P   : animate6DoF と同じ struct (t,y,h,theta,vy,vh,throttle,gimbal,m)
%   OPT : speed(実時間比) fps saveGif gifFile orbit pace legDeployAlt
%
%   機体: 細身の円柱 + インターステージ黒帯 + グリッドフィン4枚 +
%         ランディングギア4本 (既定: 高度200 m以下で約1.5秒かけて展開)
%
%   See also ANIMATESOL6, ANIMATE6DOF
if nargin < 3, opt = struct(); end
gv = @(f,d) getf(opt,f,d);
spd = gv('speed',3);  fps = gv('fps',20);
saveG = gv('saveGif',false);  gifF = gv('gifFile','falcon9_landing.gif');
orbit = gv('orbit',true);  paceOn = gv('pace',true);
hDep = gv('legDeployAlt',200);           % ギア展開開始高度 [m]
tDep = 1.5;                              % 展開所要時間 [s]

LbTrue = cfg.veh.Lb;                                   % 実寸 (接地計算に使用)
vs = gv('vehScale',3);
Lb = LbTrue*vs;  Rb = cfg.veh.R*vs*1.6;                % 描画用拡大
%% 描画は「尾部の実高度」を基準にアンカーする. 重心基準のまま拡大すると
%% 尾部が地面下に沈んで見える (実寸の尾部 = CG - LbTrue/2).
tf = P.t(end);
nF = max(2, round(tf/spd*fps));
tt = linspace(0, tf, nF);
S  = @(f,t) interp1(P.t, f, t, 'pchip');
Su = @(f,t) interp1(P.t(1:numel(f)), f, min(t,P.t(numel(f))), 'pchip', 'extrap');

%% ---- 展開タイミング (高度が hDep を切った時刻) ----
kd = find(P.h <= hDep, 1);
if isempty(kd), tDeploy = inf; else, tDeploy = P.t(kd); end

%% ---- 図 ----
fig = figure('Color','w','Position',[80 60 1100 760],'Name','Falcon9 ホバースラム着陸');
ax = axes('Parent',fig); hold(ax,'on'); grid(ax,'on'); box(ax,'on');
xlabel(ax,'ダウンレンジ [m]'); ylabel(ax,'クロスレンジ [m]'); zlabel(ax,'高度 [m]');
xr = [min(P.y)-80, max(P.y)+80];  zr = [0, max(P.h)+60];
axis(ax,'equal'); set(ax,'XLim',xr,'YLim',[-100 100],'ZLim',zr);
view(ax,[-40 12]); camproj(ax,'perspective');
patch(ax,'XData',[xr(1) xr(2) xr(2) xr(1)],'YData',[-100 -100 100 100], ...
      'ZData',[0 0 0 0],'FaceColor',[0.88 0.90 0.92],'EdgeColor','none');
th0 = linspace(0,2*pi,50);
plot3(ax, 20*cos(th0), 20*sin(th0), zeros(size(th0)), '-','Color',[0.1 0.5 0.3],'LineWidth',2.5);
plot3(ax, P.y, zeros(size(P.y)), P.h, '-','Color',[0.75 0.78 0.82],'LineWidth',1.3);
hTrail = plot3(ax,NaN,NaN,NaN,'-','Color',[0.85 0.35 0.19],'LineWidth',2.4);

%% ---- 機体 (hgtransform, 機体軸系: x=軸方向・機首+x) ----
hT = hgtransform('Parent',ax);
nC = 24;
[cx2,cy2,cz2] = cylinder(Rb*ones(1,2), nC);
surface('Parent',hT,'XData',-Lb/2 + cz2*Lb,'YData',cy2,'ZData',cx2, ...
        'FaceColor',[0.93 0.93 0.93],'EdgeColor','none','FaceLighting','gouraud');
surface('Parent',hT,'XData',Lb/2 - Lb*0.12 + cz2*(Lb*0.12),'YData',cy2*1.02,'ZData',cx2*1.02, ...
        'FaceColor',[0.15 0.15 0.18],'EdgeColor','none');           % インターステージ黒帯
surface('Parent',hT,'XData',-Lb/2 + cz2*(Lb*0.06),'YData',cy2*1.02,'ZData',cx2*1.02, ...
        'FaceColor',[0.20 0.20 0.24],'EdgeColor','none');           % 尾部黒帯
%% グリッドフィン 4枚 (上部, 小さなパドル)
for kk = 1:4
    phi = pi/4 + (kk-1)*pi/2;
    er = [0, cos(phi), sin(phi)];
    b0 = [Lb*0.34, 1.05*Rb*er(2), 1.05*Rb*er(3)];
    gw = Rb*0.85;  gh = Lb*0.045;
    et = [0, -er(3), er(2)];
    vx = [b0; b0+gw*er; b0+gw*er+gh*[1 0 0]; b0+gh*[1 0 0]];
    patch('Parent',hT,'XData',vx(:,1),'YData',vx(:,2),'ZData',vx(:,3), ...
          'FaceColor',[0.35 0.35 0.4],'EdgeColor',[0.2 0.2 0.2]); %#ok<NASGU>
end
%% ランディングギア 4本 (毎フレーム更新の line で描く)
legLen = Lb*0.18;
dAx = 0.35;  dRad = 1.10;                              % 展開方向 (軸下向き/半径外向き)
legDrop = legLen*dAx/norm([dAx dRad]);                 % 脚先端が尾部より下に出る量
hLegs = plot3(ax,NaN,NaN,NaN,'-','Color',[0.25 0.25 0.3],'LineWidth',1.2);
%% プルーム
[px,py,pz] = cylinder([0.12 0.75], 16);
hPlume = surface('Parent',hT,'XData',zeros(size(pz)),'YData',Rb*px,'ZData',Rb*py, ...
                 'FaceColor',[0.98 0.7 0.2],'EdgeColor','none','FaceAlpha',0.85);
light(ax,'Position',[-1 -1 1],'Style','infinite'); lighting(ax,'gouraud'); material(ax,'dull');
hTxt = text(ax, xr(1)+15, 0, zr(2)-25, '', 'FontSize',11, 'FontName','Yu Gothic UI', ...
            'BackgroundColor','w');

%% ---- アニメーション ----
tWall = tic;
for k = 1:nF
    t = tt(k);
    y = S(P.y,t);  h = S(P.h,t);  a = S(P.theta,t);
    tr = Su(P.throttle,t);  gi = Su(P.gimbal,t);
    bx = [sin(a); 0; cos(a)];  by = [0;1;0];  bz = cross(bx,by);
    %% 尾部アンカー: 実寸での尾部位置を求め (CG - LbTrue/2), 地面下ならクランプ.
    %% 描画中心 = 尾部 + 拡大後の半長 (拡大は機首方向へ伸ばす)
    tailP = [y;0;h] - (LbTrue/2)*bx;
    if tailP(3) < legDrop + 0.2, tailP(3) = legDrop + 0.2; end   % 脚接地で静止して見える
    ctr = tailP + (Lb/2)*bx;
    M = eye(4);  M(1:3,1:3) = [bx by bz];  M(1:3,4) = ctr;
    set(hT,'Matrix',M);
    %% ギア展開率 s: 0(格納)->1(展開)
    s = min(max((t - tDeploy)/tDep, 0), 1);
    X=[];Y=[];Z=[];
    for kk = 1:4
        phi = pi/4 + (kk-1)*pi/2;
        er = [0; cos(phi); sin(phi)];
        base = [-Lb/2 + Lb*0.05; Rb*er(2); Rb*er(3)];
        dFold = [0.98; 0.20*er(2); 0.20*er(3)];             % 機体沿い上向き
        dDep  = [-dAx; dRad*er(2); dRad*er(3)];             % 下外向き
        d = (1-s)*dFold + s*dDep;  d = d/norm(d);
        tip = base + legLen*d;
        pB = M(1:3,1:3)*base + M(1:3,4);
        pT = M(1:3,1:3)*tip  + M(1:3,4);
        X=[X pB(1) pT(1) NaN]; Y=[Y pB(2) pT(2) NaN]; Z=[Z pB(3) pT(3) NaN]; %#ok<AGROW>
    end
    set(hLegs,'XData',X,'YData',Y,'ZData',Z);
    %% プルーム
    Lp = (0.4 + 3.5*tr)*Rb;
    set(hPlume,'XData',-Lb/2 - Lp*pz,'YData',Rb*0.8*px.*(1-0.5*pz),'ZData',Rb*0.8*py.*(1-0.5*pz));
    set(hPlume,'Visible', matlab.lang.OnOffSwitchState(tr > 0.02));
    m = P.t <= t;
    set(hTrail,'XData',[P.y(m) y],'YData',zeros(1,sum(m)+1),'ZData',[P.h(m) h]);
    set(hTxt,'String',sprintf(' t=%.1fs  高度=%.0fm  スロットル=%.0f%%  ギア %s', ...
        t, h, tr*100, ternary(s>=1,'展開',ternary(s>0,'展開中','格納'))));
    if orbit, view(ax,[-40 + 20*t/tf, 12 + 4*sin(pi*t/tf)]); end
    drawnow limitrate
    if paceOn && ~saveG
        while toc(tWall) < k/fps, pause(0.001); end
    end
    if saveG
        fr = getframe(fig);  [ind,cm] = rgb2ind(frame2im(fr),256);
        if k == 1, imwrite(ind,cm,gifF,'gif','LoopCount',inf,'DelayTime',1/fps);
        else,      imwrite(ind,cm,gifF,'gif','WriteMode','append','DelayTime',1/fps); end
    end
end
if saveG, fprintf('GIF 保存: %s\n', gifF); end
end

function y = getf(s,f,d)
if isfield(s,f), y = s.(f); else, y = d; end
end
function s = ternary(c,a,b), if c, s=a; else, s=b; end, end
