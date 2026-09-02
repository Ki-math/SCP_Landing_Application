function animateVehicleAx(ax, t, X, U, cfg, opt)
%ANIMATEVEHICLEAX  指定した axes 内で着陸アニメーションを再生 (GUI統合用).
%
%   ANIMATEVEHICLEAX(AX, T, X, U, CFG, OPT)
%   AX  : 描画先 axes (uiaxes 可)
%   T   : 1xN 時刻, X : 14xN 状態(物理), U : 7xN 制御(無次元)
%   OPT : style ('starship'|'falcon9'), speed, fps, vehScale, legDeployAlt,
%         orbit, pace, saveGif, gifFile
%         vehScale=1 と orbit=false が既定 (実寸比・固定ビュー).
%
%   別ウィンドウを開かず AX に直接描画する. 尾部アンカー方式 (接地整合).
%
%   See also SCPAPP, ANIMATESOL6
if nargin < 6, opt = struct(); end
gv = @(f,d) getf(opt,f,d);
style = gv('style','starship');
spd = gv('speed',4);  fps = gv('fps',20);
vs  = gv('vehScale',1);
hDep = gv('legDeployAlt',200);  tDep = 1.5;
isF9 = strcmp(style,'falcon9');
orbit = gv('orbit',false);
paceOn = gv('pace',true);
saveGif = gv('saveGif',false);
gifFile = gv('gifFile','landing.gif');

N = numel(t);
if size(U,2) < N, U = [U, repmat(U(:,end),1,N-size(U,2))]; end
%% 状態変換 (機首角/慣性速度/スロットル)
y = X(3,:);  h = X(1,:);
th = zeros(1,N);
for k = 1:N
    q = X(7:10,k)/norm(X(7:10,k));
    R = quat2R(q);  nose = R.'*[1;0;0];
    th(k) = atan2(nose(3), nose(1));
end
thr = min(1, max(0, vecnorm(U(1:3,:))/(cfg.veh.thrustPerEng/cfg.Fs)));
LbT = cfg.veh.Lb;  Lb = LbT*vs;  Rb = cfg.veh.R*vs;
kd = find(h <= hDep, 1);
if isempty(kd), tDeploy = inf; else, tDeploy = t(kd); end

%% ---- 描画セットアップ ----
cla(ax);  hold(ax,'on');  grid(ax,'on');
xr = [min(y)-80, max(y)+80];  zr = [0, max(h)+60];
axis(ax,'equal');  set(ax,'XLim',xr,'YLim',[-100 100],'ZLim',zr);
view(ax,[-40 12]);
xlabel(ax,'ダウンレンジ [m]'); zlabel(ax,'高度 [m]');
patch(ax,'XData',[xr(1) xr(2) xr(2) xr(1)],'YData',[-100 -100 100 100], ...
      'ZData',[0 0 0 0],'FaceColor',[0.88 0.90 0.92],'EdgeColor','none');
a0 = linspace(0,2*pi,40);
plot3(ax, 20*cos(a0), 20*sin(a0), zeros(size(a0)), '-','Color',[0.1 0.5 0.3],'LineWidth',2);
plot3(ax, y, zeros(1,N), h, '-','Color',[0.75 0.78 0.82],'LineWidth',1.2);
hTrail = plot3(ax,NaN,NaN,NaN,'-','Color',[0.85 0.35 0.19],'LineWidth',2.2);

hT = hgtransform('Parent',ax);
nC = 20;
[cx2,cy2,cz2] = cylinder(Rb*ones(1,2), nC);
surface('Parent',hT,'XData',-Lb/2 + cz2*Lb*(1-0.14*~isF9),'YData',cy2,'ZData',cx2, ...
        'FaceColor',[0.82 0.84 0.87],'EdgeColor','none','FaceLighting','gouraud');
if isF9
    surface('Parent',hT,'XData',Lb/2-Lb*0.12+cz2*(Lb*0.12),'YData',cy2*1.02,'ZData',cx2*1.02, ...
            'FaceColor',[0.15 0.15 0.18],'EdgeColor','none');
    for kk = 1:4                                     % グリッドフィン
        phi = pi/4 + (kk-1)*pi/2;  er = [0, cos(phi), sin(phi)];
        b0 = [Lb*0.34, 1.05*Rb*er(2), 1.05*Rb*er(3)];
        gw = Rb*0.85;  gh = Lb*0.045;
        vx = [b0; b0+gw*er; b0+gw*er+gh*[1 0 0]; b0+gh*[1 0 0]];
        patch('Parent',hT,'XData',vx(:,1),'YData',vx(:,2),'ZData',vx(:,3), ...
              'FaceColor',[0.35 0.35 0.4],'EdgeColor','none');
    end
else
    [nx2,ny2,nz2] = cylinder(Rb*[1 0.06], nC);       % ノーズコーン (テーパ)
    surface('Parent',hT,'XData',Lb/2-Lb*0.14+nz2*(Lb*0.14),'YData',ny2,'ZData',nx2, ...
            'FaceColor',[0.72 0.74 0.78],'EdgeColor','none','FaceLighting','gouraud');
    %% ベリーフラップ 4枚 (前2小 + 後2大, 台形, 外側へ約35degのカント)
    cant = deg2rad(35);
    flapDef = { +0.32*Lb, +1, 0.13*Lb, 0.85*Rb;  +0.32*Lb, -1, 0.13*Lb, 0.85*Rb; ...
                -0.37*Lb, +1, 0.19*Lb, 1.25*Rb;  -0.37*Lb, -1, 0.19*Lb, 1.25*Rb };
    for kk = 1:4
        xb = flapDef{kk,1};  sgn = flapDef{kk,2};
        ch = flapDef{kk,3};  sp  = flapDef{kk,4};
        spy = sgn*sp*cos(cant);  spz = -sp*sin(cant);
        tp = 0.55;                                    % 先端の弦長比 (台形)
        vx = [xb-ch/2, xb+ch/2, xb+ch*tp/2, xb-ch*tp/2];
        vy = [sgn*Rb, sgn*Rb, sgn*Rb+spy, sgn*Rb+spy];
        vz = [0, 0, spz, spz];
        patch('Parent',hT,'XData',vx,'YData',vy,'ZData',vz, ...
              'FaceColor',[0.50 0.53 0.58],'EdgeColor',[0.32 0.35 0.40], ...
              'FaceLighting','gouraud');
    end
end
light(ax,'Position',[-1 -1 1],'Style','infinite');
lighting(ax,'gouraud');  material(ax,'dull');
legLen = Lb*0.18;  dAx = 0.35;  dRad = 1.10;
legDrop = legLen*dAx/norm([dAx dRad]);
hLegs = plot3(ax,NaN,NaN,NaN,'-','Color',[0.25 0.25 0.3],'LineWidth',1.2);
[px,py,pz] = cylinder([0.12 0.7], 14);
hPlume = surface('Parent',hT,'XData',zeros(size(pz)),'YData',Rb*px,'ZData',Rb*py, ...
                 'FaceColor',[0.98 0.7 0.2],'EdgeColor','none','FaceAlpha',0.85);
hTxt = text(ax, xr(1)+15, 0, zr(2)-25, '', 'FontSize',10, 'BackgroundColor','w');

%% ---- 再生 ----
tf = t(end);  nF = max(2, round(tf/spd*fps));
tt = linspace(0, tf, nF);
S = @(f,tq) interp1(t, f, tq, 'pchip');
tWall = tic;
for k = 1:nF
    if ~isvalid(ax), return; end                     % アプリが閉じられたら中断
    tq = tt(k);
    yq = S(y,tq);  hq = S(h,tq);  aq = S(th,tq);  trq = S(thr,tq);
    bx = [sin(aq); 0; cos(aq)];  by = [0;1;0];  bz = cross(bx,by);
    tailP = [yq;0;hq] - (LbT/2)*bx;                  % 尾部アンカー (実寸)
    dMin = 0.2 + legDrop*isF9;
    if tailP(3) < dMin, tailP(3) = dMin; end
    ctr = tailP + (Lb/2)*bx;
    M = eye(4);  M(1:3,1:3) = [bx by bz];  M(1:3,4) = ctr;
    set(hT,'Matrix',M);
    if isF9                                          % 脚 (展開アニメ)
        s = min(max((tq - tDeploy)/tDep, 0), 1);
        Xl=[];Yl=[];Zl=[];
        for kk = 1:4
            phi = pi/4 + (kk-1)*pi/2;  er = [0; cos(phi); sin(phi)];
            base = [-Lb/2 + Lb*0.05; Rb*er(2); Rb*er(3)];
            dF = [0.98; 0.20*er(2); 0.20*er(3)];
            dD = [-dAx; dRad*er(2); dRad*er(3)];
            d = (1-s)*dF + s*dD;  d = d/norm(d);
            tip = base + legLen*d;
            pB = M(1:3,1:3)*base + M(1:3,4);  pT = M(1:3,1:3)*tip + M(1:3,4);
            Xl=[Xl pB(1) pT(1) NaN]; Yl=[Yl pB(2) pT(2) NaN]; Zl=[Zl pB(3) pT(3) NaN]; %#ok<AGROW>
        end
        set(hLegs,'XData',Xl,'YData',Yl,'ZData',Zl);
    end
    Lp = (0.4 + 3.2*trq)*Rb;
    set(hPlume,'XData',-Lb/2 - Lp*pz,'YData',Rb*0.8*px.*(1-0.5*pz),'ZData',Rb*0.8*py.*(1-0.5*pz));
    set(hPlume,'Visible', matlab.lang.OnOffSwitchState(trq > 0.02));
    m = t <= tq;
    set(hTrail,'XData',[y(m) yq],'YData',zeros(1,sum(m)+1),'ZData',[h(m) hq]);
    set(hTxt,'String',sprintf(' t=%.1fs  高度=%.0fm  スロットル=%.0f%%', tq, hq, trq*100));
    if orbit
        view(ax,[-40 + 20*tq/tf, 12 + 4*sin(pi*tq/tf)]);
    end
    drawnow limitrate
    if paceOn && ~saveGif
        while toc(tWall) < k/fps, pause(0.001); end  % 壁時計ペーシング
    end
    if saveGif
        frame = getframe(ancestor(ax,'figure'));
        [indexedFrame,colorMap] = rgb2ind(frame2im(frame),256);
        if k == 1
            imwrite(indexedFrame,colorMap,gifFile,'gif', ...
                'LoopCount',inf,'DelayTime',1/fps);
        else
            imwrite(indexedFrame,colorMap,gifFile,'gif', ...
                'WriteMode','append','DelayTime',1/fps);
        end
    end
end
if saveGif, fprintf('GIF 保存: %s\n', gifFile); end
end

function R = quat2R(q)
q0=q(1); q1=q(2); q2=q(3); q3=q(4);
R = [1-2*(q2*q2+q3*q3),   2*(q1*q2+q0*q3),   2*(q1*q3-q0*q2);
       2*(q1*q2-q0*q3), 1-2*(q1*q1+q3*q3),   2*(q2*q3+q0*q1);
       2*(q1*q3+q0*q2),   2*(q2*q3-q0*q1), 1-2*(q1*q1+q2*q2)];
end

function y = getf(s,f,d)
if isfield(s,f), y = s.(f); else, y = d; end
end
