function out = runMCS_scp(dispFile, N, seed, prm0)
%RUNMCS_SCP  SCPパイプライン (計画+追従MPC+再計画) のモンテカルロ解析.
%
%   OUT = RUNMCS_SCP(DISPFILE, N)            変動定義と標本数を指定
%   OUT = RUNMCS_SCP(DISPFILE, N, SEED)      乱数シード固定 (再現用)
%   OUT = RUNMCS_SCP(DISPFILE, N, SEED, PRM) 追加設定:
%     PRM.parallel = true   parfor で並列実行 (Parallel Computing Toolbox)
%     PRM.planFile          対象計画 (機体) の指定 (既定 landing_vert.mat)
%     その他のフィールドは全ランの共通設定として runClosedLoopReplan へ
%
%   DISPFILE: config/ の変動パラメータ定義 (例 'dispersions_starship').
%   各ランは runClosedLoopReplan を変動パラメータで実行し, 終端指標を集計.
%   結果: results/mcs_scp.mat + 散布図/統計表示.
%
%   例: out = runMCS_scp('dispersions_starship', 20, 1, struct('parallel',true));
%
%   See also DISPERSIONS_STARSHIP, RUNCLOSEDLOOPREPLAN, RUN_MAIN
if nargin < 2, N = 8; end
if nargin >= 3 && ~isempty(seed), rng(seed); else, rng('shuffle'); end
if nargin < 4, prm0 = struct(); end
usePar = isfield(prm0,'parallel') && prm0.parallel;
if isfield(prm0,'parallel'), prm0 = rmfield(prm0,'parallel'); end
progFcn = [];                                   % 進捗コールバック progFcn(done,N)
if isfield(prm0,'progressFcn')
    progFcn = prm0.progressFcn;  prm0 = rmfield(prm0,'progressFcn');
end
here = fileparts(mfilename('fullpath'));  proj = fileparts(here);
addpath(fullfile(proj,'src'), fullfile(proj,'src','cpp'), fullfile(proj,'config'), here);
spec = loadDispersions(dispFile);       % .m 関数名 / .json パス / cell直接指定
if iscell(dispFile), dispName = sprintf('GUI表 %d項目', size(spec,1)); else, dispName = dispFile; end
nP = size(spec,1);

%% --- 標本生成 ---
X = zeros(N,nP);
for j = 1:nP
    switch spec{j,2}
        case 'uniform', X(:,j) = spec{j,3} + (spec{j,4}-spec{j,3})*rand(N,1);
        case 'normal',  X(:,j) = spec{j,3} + spec{j,4}*randn(N,1);
        case 'normal3'  % 正規分布 (平均p1, 標準偏差p2) を ±3σ で打ち切り
            X(:,j) = spec{j,3} + spec{j,4}*max(-3,min(3,randn(N,1)));
        otherwise, error('未知の分布: %s', spec{j,2});
    end
end

%% --- ラン設定を先に全て構築 (並列/逐次で共通) ---
prms = cell(N,1);
%% 機体諸元・派生量の変動として扱う名前 (プラント側モデルの再構築に回す.
%% 制御器は公称モデルのまま = モデル誤差ロバスト性の評価になる)
vehNames = {'dryMass','landingProp','Lb','R','thrustPerEng','Isp', ...
            'throttleMin','throttleMax','tvcMax','Ixx','Iyy','Izz','rTx', ...
            'rho','CdAx','CdSide','aeroScale','LoverD','VrefSurf','surfGain', ...
            'kFlapDrag','wMaxDeg','hPad'};
%% 環境系 ('windScale' 等) は otherwise 分岐で prm に入り閉ループへ渡る
for i = 1:N
    prm = prm0;  prm.anim = false;  prm.noSave = 1;
    dr0 = [0;0;0];  dvB0 = [0;0;0];             % 既定ゼロ (変動定義が上書き)
    vehOv = struct();
    for j = 1:nP
        switch spec{j,1}
            case 'dr0x', dr0(1)=X(i,j); case 'dr0y', dr0(2)=X(i,j); case 'dr0z', dr0(3)=X(i,j);
            case 'dvBx', dvB0(1)=X(i,j); case 'dvBy', dvB0(2)=X(i,j); case 'dvBz', dvB0(3)=X(i,j);
            otherwise
                if ismember(spec{j,1}, vehNames)
                    vehOv.(spec{j,1}) = X(i,j);     % 機体諸元 -> プラントモデルへ
                else
                    prm.(spec{j,1}) = X(i,j);       % 環境・制御系 -> prm へ
                end
        end
    end
    prm.dr0 = dr0;  prm.dvB0 = dvB0;
    if ~isempty(fieldnames(vehOv)), prm.vehOv = vehOv; end
    prms{i} = prm;
end

%% --- 実行 (parfor / for) ---
res = struct('horiz',cell(N,1),'vTd',[],'tilt',[],'tEnd',[],'fuel',[],'nRe',[],'ok',[],'traj',[]);
fprintf('MCS %d ラン開始 (%s%s)\n', N, dispName, ternary(usePar,', 並列',''));
if usePar
    %% 並列: DataQueue でラン完了を受けて進捗を更新 (並列でも進捗が見える)
    if isempty(gcp('nocreate'))
        fprintf('並列プール起動中...\n');
        if ~isempty(progFcn), progFcn(0, N); end
        parpool;
    end
    dq = parallel.pool.DataQueue;
    done = 0;
    afterEach(dq, @(~) bump());
    parfor i = 1:N
        res(i) = oneRun(prms{i});
        send(dq, i);
    end
else
    for i = 1:N
        res(i) = oneRun(prms{i});
        if ~isempty(progFcn), progFcn(i, N); end
        fprintf('  run %2d/%d: 水平%6.1fm |v|%5.2f 傾斜%5.1fdeg 再計画%d %s\n', ...
            i, N, res(i).horiz, res(i).vTd, res(i).tilt, res(i).nRe, ternary(res(i).ok,'OK','NG'));
    end
end

%% --- 集計 ---
h = [res.horiz];  v = [res.vTd];  tl = [res.tilt];
fprintf('\n=== MCS 集計 (%d ラン) ===\n', N);
fprintf('成功率: %.0f%%\n', 100*mean([res.ok]));
fprintf('水平誤差 : 平均%.1f / 最大%.1f m\n', mean(h,'omitnan'), max(h));
fprintf('接地速度 : 平均%.2f / 最大%.2f m/s\n', mean(v,'omitnan'), max(v));
fprintf('傾斜     : 平均%.1f / 最大%.1f deg\n', mean(tl,'omitnan'), max(tl));

if ~(isfield(prm0,'noPlot') && prm0.noPlot)
    figure('Color','w','Name','MCS: SCP着陸','Position',[60 60 1250 520]);
    subplot(1,3,1); plotMcsBirdseye(gca, res); title('飛行軌道 (鳥瞰)');
    subplot(1,3,2); scatter(h, v, 40, tl, 'filled'); colorbar; grid on;
    xlabel('水平誤差 [m]'); ylabel('接地速度 [m/s]'); title('着陸精度 (色=傾斜deg)');
    subplot(1,3,3); histogram(h, 12); grid on; xlabel('水平誤差 [m]'); ylabel('ラン数');
end

out = struct('res',res,'X',X,'spec',{spec},'N',N);
save(fullfile(proj,'results','mcs_scp.mat'),'-struct','out');
fprintf('保存: results/mcs_scp.mat\n');

function bump()
    done = done + 1;
    fprintf('  完了 %d/%d\n', done, N);
    if ~isempty(progFcn), progFcn(done, N); end
end
end

function r = oneRun(prm)
%ONERUN  1標本の閉ループ実行と指標抽出 (parfor 安全).
%% 成功判定のしきい値 (ミッション要求. prm.okCrit で機体別に指定)
okc = struct('horiz',30,'vz',5,'tilt',10);
if isfield(prm,'okCrit') && ~isempty(prm.okCrit)
    fn = fieldnames(prm.okCrit);
    for k = 1:numel(fn), okc.(fn{k}) = prm.okCrit.(fn{k}); end
    prm = rmfield(prm,'okCrit');
end
try
    [~,R] = evalc('runClosedLoopReplan(prm)');   % コンソール出力を抑制
    xE = R.xEnd;  q = xE(7:10)/norm(xE(7:10));
    rdI = quat2dcm(q.').'*xE(4:6);
    r.horiz = hypot(xE(2),xE(3));
    r.vTd   = norm(rdI);
    r.tilt  = acosd(max(-1,min(1,1-2*(q(3)^2+q(4)^2))));
    r.tEnd  = R.tEnd;
    r.fuel  = (R.plan.cfg.m0 - xE(14))/1e3;
    r.nRe   = R.rp.n;
    r.ok    = r.horiz < okc.horiz && r.vTd < okc.vz && r.tilt < okc.tilt;
    r.traj  = R.log.x(1:3, 1:3:end);        % 鳥瞰図用の軌道 [高度;クロス;ダウンレンジ]
catch
    r = struct('horiz',nan,'vTd',nan,'tilt',nan,'tEnd',nan,'fuel',nan,'nRe',0, ...
               'ok',false,'traj',zeros(3,0));
end
end

function s = ternary(c,a,b), if c, s=a; else, s=b; end, end
