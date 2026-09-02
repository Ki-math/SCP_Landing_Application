function generateReadmeMedia()
%GENERATEREADMEMEDIA Generate the GUI media embedded in README.md.
%
%   GENERATEREADMEMEDIA uses checked-in results, so regenerating the
%   documentation does not rerun trajectory optimization or Monte Carlo.

utilDir = fileparts(mfilename('fullpath'));
projectDir = fileparts(utilDir);
mediaDir = fullfile(projectDir, 'docs', 'media');
if ~isfolder(mediaDir)
    mkdir(mediaDir);
end

addpath(fullfile(projectDir, 'src'), utilDir);
falcon9 = load(fullfile(projectDir, 'results', 'closedloop_replan.mat'));
falcon9.log = landingSegment(falcon9.log, 450);
starship = load(fullfile(projectDir, 'results', 'landing_vert.mat'));
starship.log = landingSegment(solutionLog(starship.sol), 600);
mcs = load(fullfile(projectDir, 'results', 'mcs_scp.mat'));

createGuiSnapshot(projectDir, mediaDir, starship);
createFalcon9Animation(mediaDir, falcon9);
createStarshipAnimation(mediaDir, starship);
createMcsSnapshot(mediaDir, mcs);
end

function createGuiSnapshot(projectDir, mediaDir, result)
oldApp = findall(groot, 'Type', 'figure', 'Name', 'SCP着陸解析ツール');
delete(oldApp);

originalDir = pwd;
cleanupDir = onCleanup(@() cd(originalDir));
cd(projectDir);
setup;
scpApp;
drawnow;

app = findall(groot, 'Type', 'figure', 'Name', 'SCP着陸解析ツール');
if isempty(app)
    error('generateReadmeMedia:AppNotFound', ...
        'scpApp did not create the expected GUI window.');
end
app = app(1);
cleanupApp = onCleanup(@() deleteValid(app));

vehicleMenus = findall(app, 'Type', 'uidropdown');
for k = 1:numel(vehicleMenus)
    items = string(vehicleMenus(k).Items);
    if all(ismember(["starship", "falcon9"], items))
        vehicleMenus(k).Value = 'starship';
        callback = vehicleMenus(k).ValueChangedFcn;
        if isa(callback, 'function_handle')
            callback(vehicleMenus(k), []);
        elseif iscell(callback)
            feval(callback{1}, vehicleMenus(k), [], callback{2:end});
        end
        break
    end
end

tabs = findall(app, 'Type', 'uitab');
selectTab(tabs, '機体');
animationTab = selectTab(tabs, 'アニメーション');
animationAxes = findall(animationTab, 'Type', 'axes');
if isempty(animationAxes)
    error('generateReadmeMedia:AxesNotFound', ...
        'The GUI animation axes could not be found.');
end

animationOptions = struct( ...
    'style', 'starship', ...
    'speed', 1e6, ...
    'fps', 2, ...
    'vehScale', 1, ...
    'orbit', false);
animateVehicleAx(animationAxes(1), result.log.t, result.log.x, ...
    result.log.u, result.cfg, animationOptions);
logAreas = findall(app, 'Type', 'uitextarea');
if ~isempty(logAreas)
    logAreas(1).Value = { ...
        '[README] 保存済みStarship計画のフリップ着陸を表示中'; ...
        '計画・閉ループ・再生・MCS・コード生成をGUIから実行できます。'};
end
drawnow;

snapshotFile = fullfile(mediaDir, 'scp_gui.png');
exportapp(app, snapshotFile);
fprintf('README GUI snapshot: %s\n', snapshotFile);

clear cleanupApp cleanupDir
end

function createFalcon9Animation(mediaDir, result)
log = result.log;
cfg = result.plan.cfg;
numSamples = numel(log.t);
theta = attitudeAngle(log.x);

thrustScale = cfg.veh.thrustPerEng / cfg.Fs;
throttle = min(1, max(0, vecnorm(log.u(1:3, :)) / thrustScale));
animationData = struct( ...
    't', log.t, ...
    'y', log.x(3, :), ...
    'h', log.x(1, :), ...
    'theta', theta, ...
    'vy', log.x(6, :), ...
    'vh', log.x(4, :), ...
    'throttle', throttle, ...
    'gimbal', zeros(1, numSamples), ...
    'm', log.x(14, :));

gifFile = fullfile(mediaDir, 'falcon9_landing.gif');
animationOptions = struct( ...
    'speed', 2, ...
    'fps', 12, ...
    'saveGif', true, ...
    'gifFile', gifFile, ...
    'orbit', false, ...
    'pace', false, ...
    'vehScale', 1, ...
    'legDeployAlt', 200);
animateFalcon9(animationData, cfg, animationOptions);
animationFigure = findall(groot, 'Type', 'figure', ...
    'Name', 'Falcon9 ホバースラム着陸');
delete(animationFigure);
fprintf('README landing animation: %s\n', gifFile);
end

function createStarshipAnimation(mediaDir, result)
animationFigure = figure( ...
    'Color','w', ...
    'Position',[80 60 900 760], ...
    'Name','Starship フリップ着陸');
cleanupFigure = onCleanup(@() deleteValid(animationFigure));
animationAxes = axes('Parent',animationFigure);
gifFile = fullfile(mediaDir, 'starship_landing.gif');
animationOptions = struct( ...
    'style', 'starship', ...
    'speed', 8, ...
    'fps', 12, ...
    'saveGif', true, ...
    'gifFile', gifFile, ...
    'orbit', false, ...
    'pace', false, ...
    'vehScale', 1);
animateVehicleAx(animationAxes, result.log.t, result.log.x, ...
    result.log.u, result.cfg, animationOptions);
fprintf('README Starship animation: %s\n', gifFile);
clear cleanupFigure
end

function createMcsSnapshot(mediaDir, mcs)
result = mcs.res;
horiz = [result.horiz];
touchdownSpeed = [result.vTd];
tilt = [result.tilt];
successRate = 100 * mean([result.ok]);

mcsFigure = figure( ...
    'Color','w', ...
    'Position',[60 60 1450 720], ...
    'Name','Falcon 9 MCS');
cleanupFigure = onCleanup(@() deleteValid(mcsFigure));
layout = tiledlayout(mcsFigure,2,2, ...
    'TileSpacing','compact','Padding','loose');

birdseyeAxes = nexttile(layout,[2 1]);
plotMcsBirdseye(birdseyeAxes,result);
title(birdseyeAxes,sprintf('飛行軌道（%dラン、青=成功 / 赤=NG）',mcs.N));

scatterAxes = nexttile(layout);
scatter(scatterAxes,horiz,touchdownSpeed,42,tilt,'filled');
hold(scatterAxes,'on');
xline(scatterAxes,mcs.prm.okCrit.horiz,'--','水平誤差上限');
yline(scatterAxes,mcs.prm.okCrit.vz,'--','接地速度上限');
grid(scatterAxes,'on');
colorbar(scatterAxes);
xlabel(scatterAxes,'水平誤差 [m]');
ylabel(scatterAxes,'接地速度 [m/s]');
title(scatterAxes,'着陸精度（色=傾斜 [deg]）');

histogramAxes = nexttile(layout);
histogram(histogramAxes,horiz,12);
hold(histogramAxes,'on');
xline(histogramAxes,mcs.prm.okCrit.horiz,'--r','成功判定上限');
grid(histogramAxes,'on');
xlabel(histogramAxes,'水平誤差 [m]');
ylabel(histogramAxes,'ラン数');
title(histogramAxes,sprintf('水平誤差（平均 %.1f m / 最大 %.1f m）', ...
    mean(horiz),max(horiz)));

title(layout,sprintf( ...
    'Falcon 9 モンテカルロ解析 — 成功率 %.0f%%、接地速度平均 %.1f m/s、傾斜平均 %.1f°', ...
    successRate,mean(touchdownSpeed),mean(tilt)));
mcsFile = fullfile(mediaDir,'falcon9_mcs.png');
exportgraphics(mcsFigure,mcsFile,'Resolution',150);
fprintf('README MCS snapshot: %s\n',mcsFile);
clear cleanupFigure
end

function tab = selectTab(tabs, titleText)
tab = tabs(strcmp({tabs.Title}, titleText));
if isempty(tab)
    error('generateReadmeMedia:TabNotFound', ...
        'GUI tab "%s" could not be found.', titleText);
end
tab = tab(1);
tab.Parent.SelectedTab = tab;
end

function log = landingSegment(log, startAltitude)
startIndex = find(log.x(1, :) <= startAltitude, 1, 'first');
if isempty(startIndex)
    startIndex = 1;
end
log.t = log.t(startIndex:end) - log.t(startIndex);
log.x = log.x(:, startIndex:end);
log.u = log.u(:, startIndex:end);
end

function log = solutionLog(solution)
log = struct( ...
    't', solution.t, ...
    'x', [solution.r; solution.v; solution.q; solution.w; solution.m], ...
    'u', solution.uhat);
end

function theta = attitudeAngle(state)
numSamples = size(state,2);
theta = zeros(1,numSamples);
for k = 1:numSamples
    q = state(7:10,k);
    q = q / norm(q);
    q0 = q(1);
    q1 = q(2);
    q2 = q(3);
    q3 = q(4);
    rotation = [ ...
        1-2*(q2*q2+q3*q3), 2*(q1*q2+q0*q3), 2*(q1*q3-q0*q2); ...
        2*(q1*q2-q0*q3), 1-2*(q1*q1+q3*q3), 2*(q2*q3+q0*q1); ...
        2*(q1*q3+q0*q2), 2*(q2*q3-q0*q1), 1-2*(q1*q1+q2*q2)];
    nose = rotation.' * [1; 0; 0];
    theta(k) = atan2(nose(3),nose(1));
end
end

function deleteValid(object)
if isvalid(object)
    delete(object);
end
end
