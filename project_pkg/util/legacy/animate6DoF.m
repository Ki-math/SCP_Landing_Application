function animate6DoF(sol,cfg,opt)
%ANIMATE6DOF  平面6-DoF 解を3次元アニメーションで表示する.
%  座標: X = ダウンレンジ (sol.y), Y = クロスレンジ (0), Z = 高度 (sol.h)
%  機体軸 b = [sin(theta); 0; cos(theta)]  (theta=0 でテールダウン, 90deg でベリーフロップ)
%  使い方:  animate6DoF(sBest,cfg)  /  animate6DoF(sBest,cfg,struct('saveGif',true))
if nargin < 3, opt = struct(); end
gv = @(f,d) getf(opt,f,d);
spd    = gv('speed',0.4);        % 再生速度 (実時間比)
fps    = gv('fps',30);
saveG  = gv('saveGif',false);
gifF   = gv('gifFile','flip_landing.gif');
orbit  = gv('orbit',true);
trail  = gv('trail',true);
refT   = gv('refTraj',[]);   % 計画軌道の重ね描き用 struct('y',..,'h',..)
paceOn = gv('pace',true);    % 壁時計に同期して再生 (無いと描画速度で一瞬に終わる)

av = attVehicle(); Lb = av.L; Rb = av.R;
tf = sol.t(end);
nF = max(2,round(tf/spd*fps));
tt = linspace(0,tf,nF);
S  = @(f,t) interp1(sol.t,f,t,'pchip');
Su = @(f,t) interp1(sol.t(1:numel(f)),f,min(t,sol.t(numel(f))),'pchip','extrap');

%% ---- 図の準備 ----
fig = figure('Color','w','Position',[80 60 1180 760],'Name','Starship flip & landing (planar 6-DoF)');
JF  = 'Yu Gothic UI';   % 日本語グリフを持つフォント (Consolas には無い)
ax  = axes('Parent',fig,'Units','normalized','Position',[0.02 0.07 0.72 0.88],'FontName',JF);
hold(ax,'on'); axis(ax,'equal'); grid(ax,'on'); box(ax,'off');
xr = [min(sol.y)-60, max(sol.y)+60];
set(ax,'XLim',xr,'YLim',[-90 90],'ZLim',[0 max(sol.h)+40]);
xlabel(ax,'ダウンレンジ [m]','FontName',JF); ylabel(ax,'クロスレンジ [m]','FontName',JF);
zlabel(ax,'高度 [m]','FontName',JF);
view(ax,[-38 14]); camproj(ax,'perspective');
light(ax,'Position',[-1 -1 1],'Style','infinite'); lighting(ax,'gouraud'); material(ax,'dull');

% 地面と目標
gx = [xr(1) xr(2) xr(2) xr(1)]; gy = [-90 -90 90 90];
patch(ax,'XData',gx,'YData',gy,'ZData',zeros(1,4),'FaceColor',[0.90 0.92 0.94],'EdgeColor','none');
th = linspace(0,2*pi,60);
plot3(ax,25*cos(th),25*sin(th),zeros(size(th)),'Color',[0.10 0.55 0.35],'LineWidth',2.5);
plot3(ax,[0 0],[0 0],[0 Lb*0.5],'Color',[0.10 0.55 0.35],'LineWidth',1.2,'LineStyle',':');

% 全体軌道 (薄) と通過済み軌跡 (濃)
plot3(ax,sol.y,zeros(size(sol.y)),sol.h,'Color',[0.72 0.74 0.78],'LineWidth',1.5);
if ~isempty(refT)
    plot3(ax,refT.y,zeros(size(refT.y)),refT.h,'--','Color',[0.35 0.45 0.75],'LineWidth',2.0);
end
hTrail = plot3(ax,NaN,NaN,NaN,'Color',[0.85 0.35 0.19],'LineWidth',3);
hVel = quiver3(ax,0,0,0,0,0,0,'Color',[0.22 0.54 0.87],'LineWidth',2.5,'MaxHeadSize',0.6,'AutoScale','off');

%% ---- 機体の構築 (hgtransform で駆動) ----
hT = hgtransform('Parent',ax);
nC = 28;
[cx,cy,cz] = cylinder(Rb*ones(1,2),nC);            % 胴体
bodyX = -Lb/2 + cz*(Lb*0.86);
surface('Parent',hT,'XData',bodyX,'YData',cy,'ZData',cx, ...   % 機体軸系: x=軸方向
        'FaceColor',[0.80 0.82 0.85],'EdgeColor','none','FaceLighting','gouraud');
[nx2,ny2,nz2] = cylinder(Rb*[1 0.06],nC);          % ノーズ
noseX = (Lb/2 - Lb*0.14) + nz2*(Lb*0.14);
surface('Parent',hT,'XData',noseX,'YData',ny2,'ZData',nx2, ...
        'FaceColor',[0.72 0.74 0.78],'EdgeColor','none','FaceLighting','gouraud');

% フラップ 4枚 (前2/後2). 各々が子 hgtransform を持ち舵角で回る
flapDef = { av.flapArmF,  1, 10, 6;  av.flapArmF, -1, 10, 6; ...
           -av.flapArmR,  1, 15, 9; -av.flapArmR, -1, 15, 9 };
hFlap = gobjects(4,1);
for i = 1:4
    xb = flapDef{i,1}; sgn = flapDef{i,2}; ch = flapDef{i,3}; sp = flapDef{i,4};
    hFlap(i) = hgtransform('Parent',hT);
    vx = [-ch/2 ch/2 ch/2 -ch/2]; vy = sgn*[0 0 sp sp]; vz = [0 0 0 0];
    patch('Parent',hFlap(i),'XData',vx,'YData',vy,'ZData',vz, ...
          'FaceColor',[0.55 0.58 0.62],'EdgeColor',[0.35 0.38 0.42],'FaceLighting','gouraud');
    set(hFlap(i),'Matrix',makehgtform('translate',[xb sgn*Rb 0]));
    setappdata(hFlap(i),'geo',[xb sgn]);
end

% 推力プルーム (子 hgtransform でジンバル)
hGim = hgtransform('Parent',hT);
[px,py,pz] = cylinder([0.16 1.0],20);
hPlume = surface('Parent',hGim,'XData',zeros(size(pz)),'YData',Rb*0.95*px,'ZData',Rb*0.95*py, ...
                 'FaceColor',[0.95 0.62 0.15],'EdgeColor','none','FaceAlpha',0.85);
setappdata(hPlume,'geo',{px,py,pz});

pnl = uipanel('Parent',fig,'Units','normalized','Position',[0.755 0.44 0.225 0.51], ...
    'BackgroundColor','w','Title','状態量','FontName',JF,'FontSize',11, ...
    'ForegroundColor',[0.25 0.25 0.25]);
labs = {'時刻';'高度';'速度';'機体角';'角速度';'スロットル';'ジンバル';'質量'};
uicontrol(pnl,'Style','text','Units','normalized','Position',[0.07 0.03 0.45 0.90], ...
    'String',labs,'HorizontalAlignment','left','FontName',JF,'FontSize',11, ...
    'BackgroundColor','w','ForegroundColor',[0.35 0.35 0.35]);
hVal = uicontrol(pnl,'Style','text','Units','normalized','Position',[0.45 0.03 0.48 0.90], ...
    'String',repmat({' '},8,1),'HorizontalAlignment','right','FontName',JF,'FontSize',11, ...
    'BackgroundColor','w','ForegroundColor',[0.10 0.10 0.10]);

%% ---- アニメーション ----
tWall = tic;
for k = 1:nF
    t = tt(k);
    y = S(sol.y,t); h = S(sol.h,t); a = S(sol.theta,t);
    vy = S(sol.vy,t); vh = S(sol.vh,t);
    tr = Su(sol.throttle,t); gi = Su(sol.gimbal,t); df = Su(sol.df,t);
    bx = [sin(a); 0; cos(a)];  by = [0;1;0];  bz = cross(bx,by);
    M = eye(4); M(1:3,1:3) = [bx by bz]; M(1:3,4) = [y;0;h];
    set(hT,'Matrix',M);
    for i = 1:4
        g = getappdata(hFlap(i),'geo'); xb = g(1); sgn = g(2);
        if xb < 0, del = av.flapMax*abs(df); else, del = av.flapMax*0.15; end
        set(hFlap(i),'Matrix', makehgtform('translate',[xb sgn*Rb 0])*makehgtform('xrotate',sgn*del));
    end
    P = getappdata(hPlume,'geo'); Lp = (0.5+3.2*tr)*Rb;
    set(hPlume,'XData',-Lb/2 - Lp*P{3},'YData',Rb*0.95*P{1}.*(1-0.55*P{3}),'ZData',Rb*0.95*P{2}.*(1-0.55*P{3}));
    set(hGim,'Matrix', makehgtform('translate',[-Lb/2 0 0])*makehgtform('yrotate',-gi)*makehgtform('translate',[Lb/2 0 0]));
    set(hPlume,'Visible', matlab.lang.OnOffSwitchState(tr>0.02));
    if trail
        m = sol.t <= t;
        set(hTrail,'XData',[sol.y(m) y],'YData',zeros(1,sum(m)+1),'ZData',[sol.h(m) h]);
    end
    set(hVel,'XData',y,'YData',0,'ZData',h,'UData',vy*1.1,'VData',0,'WData',vh*1.1);
    set(hVal,'String',{ sprintf('%5.2f s',t); sprintf('%6.1f m',h); ...
        sprintf('%6.1f m/s',hypot(vh,vy)); sprintf('%6.1f deg',rad2deg(a)); ...
        sprintf('%6.1f deg/s',rad2deg(S(sol.omega,t))); sprintf('%.3f',tr); ...
        sprintf('%+5.2f deg',rad2deg(gi)); sprintf('%6.2f t',S(sol.m,t)/1e3) });
    if orbit, view(ax,[-38 + 26*t/tf, 14 + 6*sin(pi*t/tf)]); end
    drawnow limitrate
    %% 壁時計ペーシング: フレーム k は開始から k/fps 秒後に表示する.
    %% (GIF保存は DelayTime で別途タイミングが入るのでスキップ)
    if paceOn && ~saveG
        while toc(tWall) < k/fps, pause(0.001); end
    end
    if saveG
        fr = getframe(fig); [ind,cm] = rgb2ind(frame2im(fr),256);
        if k == 1, imwrite(ind,cm,gifF,'gif','LoopCount',inf,'DelayTime',1/fps);
        else,      imwrite(ind,cm,gifF,'gif','WriteMode','append','DelayTime',1/fps); end
    end
end
if saveG, fprintf('GIF を保存しました: %s\n', fullfile(pwd,gifF)); end
end

function y = getf(s,f,d)
if isfield(s,f), y = s.(f); else, y = d; end
end

