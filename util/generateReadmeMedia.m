function generateReadmeMedia()
%GENERATEREADMEMEDIA Generate the GUI media embedded in README.md.
%
%   GENERATEREADMEMEDIA uses the checked-in Falcon 9 closed-loop result,
%   so regenerating the documentation does not rerun the optimizer.

utilDir = fileparts(mfilename('fullpath'));
projectDir = fileparts(utilDir);
mediaDir = fullfile(projectDir, 'docs', 'media');
if ~isfolder(mediaDir)
    mkdir(mediaDir);
end

addpath(fullfile(projectDir, 'src'), utilDir);
result = load(fullfile(projectDir, 'results', 'closedloop_replan.mat'));
result.log = landingSegment(result.log, 450);

createGuiSnapshot(projectDir, mediaDir, result);
createLandingAnimation(mediaDir, result);
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
        vehicleMenus(k).Value = 'falcon9';
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
    'style', 'falcon9', ...
    'speed', 1e6, ...
    'fps', 2, ...
    'vehScale', 2.5, ...
    'legDeployAlt', 200);
animateVehicleAx(animationAxes(1), result.log.t, result.log.x, ...
    result.log.u, result.plan.cfg, animationOptions);
logAreas = findall(app, 'Type', 'uitextarea');
if ~isempty(logAreas)
    logAreas(1).Value = { ...
        '[README] 保存済み閉ループ結果の着陸直前450 m区間を表示中'; ...
        '計画・閉ループ・再生・MCS・コード生成をGUIから実行できます。'};
end
drawnow;

snapshotFile = fullfile(mediaDir, 'scp_gui.png');
exportapp(app, snapshotFile);
fprintf('README GUI snapshot: %s\n', snapshotFile);

clear cleanupApp cleanupDir
end

function createLandingAnimation(mediaDir, result)
log = result.log;
cfg = result.plan.cfg;
numSamples = numel(log.t);
theta = zeros(1, numSamples);
for k = 1:numSamples
    q = log.x(7:10, k);
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
    theta(k) = atan2(nose(3), nose(1));
end

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
    'orbit', true, ...
    'pace', false, ...
    'legDeployAlt', 200);
animateFalcon9(animationData, cfg, animationOptions);
animationFigure = findall(groot, 'Type', 'figure', ...
    'Name', 'Falcon9 ホバースラム着陸');
delete(animationFigure);
fprintf('README landing animation: %s\n', gifFile);
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

function deleteValid(object)
if isvalid(object)
    delete(object);
end
end
