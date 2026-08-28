function ok = verifyEmbedded()
%VERIFYEMBEDDED  組み込みパッケージの等価性検証 (コンパイル済みC vs MATLAB参照).
%
%   OK = VERIFYEMBEDDED() は次を自動実行する:
%     1. scp_landing_embedded.zip を一時フォルダへ展開
%     2. MinGW gcc で examples/main_verify.c をビルド (実機と同じ純Cソース)
%     3. 実行し, 計画SCP 1反復 / 追従MPC 1周期 / GNC閉ループ (着陸までの
%        シミュレーション軌跡) の結果をファイル取得
%     4. MATLAB参照実装 (scpk.planIterEmb / scpk.trackStepEmb / scpk.dynamics6)
%        を同一入力 (results/plan_example_args.mat) で実行
%     5. 数値一致を突き合わせ, シミュレーション軌跡の重ね描き + 差のプロット
%        を表示 (Figure「等価性検証」)
%
%   判定閾値: 軌道・制御 1e-6 (無次元), 参照窓 1e-9, QP status/iters は一致,
%   閉ループ軌跡の位置差 < 0.01 m.
%
%   See also SCPCODEGENZIP, EXPORTPLANEXAMPLE, CODEGENPLANITER
here = fileparts(mfilename('fullpath'));  proj = fileparts(here);
addpath(fullfile(proj,'src'));
zipf = fullfile(proj,'scp_landing_embedded.zip');
argf = fullfile(proj,'results','plan_example_args.mat');
assert(exist(zipf,'file')==2, 'scp_landing_embedded.zip がありません (scpCodegenZip を実行)');
assert(exist(argf,'file')==2, 'plan_example_args.mat がありません (exportPlanExample を実行)');
A = load(argf);

%% --- 1. 展開 + 2. ビルド (MinGW gcc) ---
wd = fullfile(tempdir, 'scp_verify_embedded');
if exist(wd,'dir'), rmdir(wd,'s'); end
mkdir(wd);  unzip(zipf, wd);
cc = mex.getCompilerConfigurations('C','Selected');
gcc = fullfile(cc.Location, 'bin', 'gcc.exe');
assert(exist(gcc,'file')==2, 'MinGW gcc が見つかりません (%s)', gcc);
cmd = sprintf(['"%s" -O2 -Ignc -Iguidance -Iexamples ' ...
    'examples/main_verify.c gnc/*.c guidance/*.c -o verify_demo.exe -lm'], gcc);
fprintf('ビルド中 (gcc)...\n');
[s,o] = system(sprintf('cd /d "%s" && %s', wd, cmd));
assert(s==0, 'gccビルド失敗:\n%s', o);

%% --- 3. 実行 ---
[s,o] = system(sprintf('cd /d "%s" && verify_demo.exe', wd));
assert(s==0, 'verify_demo 実行失敗:\n%s', o);
fprintf('%s', o);
P = parseOut(fullfile(wd,'verify_plan.txt'));
T = parseOut(fullfile(wd,'verify_track.txt'));
G = readmatrix(fullfile(wd,'verify_gnc.txt'), 'FileType','text');   % [t, x(14)] x 行

%% --- 4. MATLAB参照 (同一入力) ---
[xs,us,~,ss,st,iters,nu,~,~] = scpk.planIterEmb(A.x0nd, A.xT, A.xl, A.ul, ...
    A.gl, A.sigl, A.phase, A.eng, A.dtv, A.tiltN, A.cfg, A.pp, A.qp, zeros(0,1));
%% 追従: 参照窓を C (gnc_ref_window) と同じ規則で作る (線形補間 + ZOH)
H = A.H;  refD = A.refD;  t0 = 2.0;
tk = min(t0 + (0:H)*A.dtMpc, refD.t(end));
xr = interp1(refD.t, refD.xhat.', tk, 'linear').';
tu = refD.t(1:size(refD.uhat,2));
ur = interp1(tu, refD.uhat.', min(tk(1:H), tu(end)), 'previous').';
if size(ur,1) ~= 7, ur = ur.'; end
for k = 1:H+1
    nq = norm(xr(7:10,k));  if nq > eps, xr(7:10,k) = xr(7:10,k)/nq; end
end
engk = reshape(interp1(tu, refD.engSched(:), min(tk(1:H), tu(end)), 'previous'),1,[]);
sc = A.cfg.sc;
sx = [repmat(sc.L,3,1); repmat(sc.V,3,1); ones(4,1); repmat(1/sc.T,3,1); A.cfg.m0];
xc = xr(:,1).*sx;
[u0,~,qCmd,st2,it2] = scpk.trackStepEmb(xc, xr, ur, engk, A.cfg, A.tp, zeros(21*H,1));

%% --- 5. 突き合わせ ---
res = {};
res(end+1,:) = chk('計画: 状態軌道 xs', xs(:), P.xs, 1e-6);
res(end+1,:) = chk('計画: 制御軌道 us', us(:), P.us, 1e-6);
res(end+1,:) = chk('計画: フェーズ時間 ss', ss(:), P.ss, 1e-6);
res(end+1,:) = chk('計画: 仮想制御 nu', nu, P.nu, 1e-6);
res(end+1,:) = {sprintf('計画: QP status/iters (MATLAB %d/%d, C %d/%d)', ...
    st, iters, P.st, P.iters), abs(double(st)-P.st)+abs(double(iters)-P.iters), ...
    double(st)==P.st && double(iters)==P.iters};
res(end+1,:) = chk('追従: 参照窓 xr (窓生成の等価性)', xr(:), T.xr, 1e-9);
res(end+1,:) = chk('追従: 参照窓 ur', ur(:), T.ur, 1e-9);
res(end+1,:) = chk('追従: 適用制御 u0', u0(:), T.u0, 1e-8);
res(end+1,:) = chk('追従: 姿勢コマンド qCmd', qCmd(:), T.qCmd, 1e-8);
res(end+1,:) = {sprintf('追従: QP status/iters (MATLAB %d/%d, C %d/%d)', ...
    st2, it2, T.st, T.iters), abs(double(st2)-T.st)+abs(double(it2)-T.iters), ...
    double(st2)==T.st && double(it2)==T.iters};

%% --- GNC閉ループ: MATLAB側で同一ループを再現し軌跡を比較 ---
fprintf('GNC閉ループのMATLAB参照を実行中 (追従MPC x 約%d周期, 1-2分)...\n', size(G,1));
L = gncTwin(A);
nC = min(size(G,1), size(L,1));
posDiff = max(vecnorm((G(1:nC,2:4) - L(1:nC,2:4)).', 1)) * sc.L;   % 位置差 [m]
res(end+1,:) = {sprintf('GNC閉ループ: 軌跡位置差 [m] (%d周期)', nC), posDiff, posDiff < 0.01};

fprintf('\n=== 等価性検証: コンパイル済みC (gcc -O2) vs MATLAB参照実装 ===\n');
ok = true;
for i = 1:size(res,1)
    fprintf('  [%s] %-42s max|diff| = %.2e\n', tern(res{i,3},'OK','NG'), res{i,1}, res{i,2});
    ok = ok && res{i,3};
end
fprintf('=== 総合判定: %s ===\n', tern(ok,'PASS (数値一致)','FAIL'));

%% --- プロット: シミュレーション軌跡の重ね描き + 差 ---
plotVerify(G, L, sc, res, ok);
end


function L = gncTwin(A)
%GNCTWIN  main_verify.c のGNC閉ループと同一のループをMATLAB参照実装で実行.
cfg = A.cfg;  tp = A.tp;  H = A.H;  refD = A.refD;  sc = cfg.sc;
sx = [repmat(sc.L,3,1); repmat(sc.V,3,1); ones(4,1); repmat(1/sc.T,3,1); cfg.m0];
dtP = 0.01;  thrEff = 0.97;  tdAlt = cfg.hmin*sc.L;
nSub = round(A.dtMpc/dtP);
x = refD.xhat(:,1);  zw = zeros(21*H,1);  t = 0;  tEnd = refD.t(end) + 10;
L = zeros(0,15);
while t < tEnd
    L(end+1,:) = [t, x.']; %#ok<AGROW>
    [xr,ur,engk] = winSample(refD, t, A.dtMpc, H);
    [u0,zw] = scpk.trackStepEmb(x.*sx, xr, ur, engk, cfg, tp, zw);
    for s = 1:nSub
        up = u0;  up(1:3) = thrEff*up(1:3);
        hP = dtP/sc.T;
        k1 = scpk.dynamics6(x,up,cfg);         k2 = scpk.dynamics6(x+hP/2*k1,up,cfg);
        k3 = scpk.dynamics6(x+hP/2*k2,up,cfg); k4 = scpk.dynamics6(x+hP*k3,up,cfg);
        x = x + hP/6*(k1+2*k2+2*k3+k4);  x(7:10) = x(7:10)/norm(x(7:10));
        t = t + dtP;
        if x(1)*sc.L <= tdAlt, break; end
    end
    if x(1)*sc.L <= tdAlt, break; end
end
L(end+1,:) = [t, x.'];
end


function [xr,ur,engk] = winSample(refD, t0, dtMpc, H)
tk = min(t0 + (0:H)*dtMpc, refD.t(end));
xr = interp1(refD.t, refD.xhat.', tk, 'linear').';
tu = refD.t(1:size(refD.uhat,2));
ur = interp1(tu, refD.uhat.', min(tk(1:H), tu(end)), 'previous').';
if size(ur,1) ~= 7, ur = ur.'; end
for k = 1:H+1
    nq = norm(xr(7:10,k));  if nq > eps, xr(7:10,k) = xr(7:10,k)/nq; end
end
engk = reshape(interp1(tu, refD.engSched(:), min(tk(1:H), tu(end)), 'previous'),1,[]);
end


function plotVerify(G, L, sc, res, ok)
figure('Color','w','Position',[50 50 1250 700], ...
       'Name','等価性検証: 生成コード(C) vs MATLAB参照実装');
tl = tiledlayout(2,3,'Padding','compact','TileSpacing','compact');
tiltOf = @(X) acosd(max(-1,min(1, 1-2*(X(:,9).^2 + X(:,10).^2))));
nC = min(size(G,1), size(L,1));
ax = nexttile(tl);  hold(ax,'on'); grid(ax,'on');
plot(ax, G(:,1), G(:,2)*sc.L, 'b-','LineWidth',1.6);
plot(ax, L(:,1), L(:,2)*sc.L, 'r--','LineWidth',1.2);
xlabel(ax,'t [s]'); ylabel(ax,'高度 [m]');
legend(ax,{'C (gcc)','MATLAB'},'Location','best'); title(ax,'高度');
ax = nexttile(tl);  hold(ax,'on'); grid(ax,'on');
plot(ax, G(:,1), G(:,3)*sc.L, 'b-', G(:,1), G(:,4)*sc.L, 'c-','LineWidth',1.6);
plot(ax, L(:,1), L(:,3)*sc.L, 'r--', L(:,1), L(:,4)*sc.L, 'm--','LineWidth',1.2);
xlabel(ax,'t [s]'); ylabel(ax,'位置 [m]');
legend(ax,{'CR (C)','DR (C)','CR (MATLAB)','DR (MATLAB)'},'Location','best');
title(ax,'水平位置');
ax = nexttile(tl);  hold(ax,'on'); grid(ax,'on');
plot(ax, G(:,1), vecnorm(G(:,5:7).')*sc.V, 'b-','LineWidth',1.6);
plot(ax, L(:,1), vecnorm(L(:,5:7).')*sc.V, 'r--','LineWidth',1.2);
xlabel(ax,'t [s]'); ylabel(ax,'|v| [m/s]'); title(ax,'速度');
ax = nexttile(tl);  hold(ax,'on'); grid(ax,'on');
plot(ax, G(:,1), tiltOf(G(:,2:15)), 'b-','LineWidth',1.6);
plot(ax, L(:,1), tiltOf(L(:,2:15)), 'r--','LineWidth',1.2);
xlabel(ax,'t [s]'); ylabel(ax,'傾斜角 [deg]'); title(ax,'姿勢');
ax = nexttile(tl);  grid(ax,'on');
dpos = vecnorm((G(1:nC,2:4) - L(1:nC,2:4)).', 1)*sc.L;
semilogy(ax, G(1:nC,1), max(dpos, 1e-16), 'k-','LineWidth',1.4);
xlabel(ax,'t [s]'); ylabel(ax,'位置差 ||r_C - r_M|| [m]');
title(ax,sprintf('閉ループ軌跡の差 (max %.1e m)', max(dpos)));
ax = nexttile(tl);  axis(ax,'off');
txt = cell(size(res,1)+2,1);
txt{1} = sprintf('総合判定: %s', tern(ok,'PASS (数値一致)','FAIL'));
txt{2} = '';
for i = 1:size(res,1)
    txt{i+2} = sprintf('[%s] %s  (%.1e)', tern(res{i,3},'OK','NG'), res{i,1}, res{i,2});
end
text(ax, 0, 0.95, txt, 'Units','normalized', 'VerticalAlignment','top', ...
     'FontName','monospaced', 'FontSize', 9, 'Interpreter','none');
title(tl, '等価性検証: コンパイル済みC (gcc -O2) vs MATLAB参照実装 (実線=C, 破線=MATLAB)');
end


function r = chk(name, a, b, tol)
d = max(abs(a(:) - b(:)));
r = {name, d, d < tol};
end

function S = parseOut(fn)
%% main_verify.c の出力 ("key n" + 値リスト / "key 値") をstructへ
txt = strsplit(strtrim(fileread(fn)), {'\r','\n'});
txt = txt(~cellfun(@isempty, txt));
S = struct();  i = 1;
while i <= numel(txt)
    parts = strsplit(strtrim(txt{i}));
    key = parts{1};  val = str2double(parts{2});
    if ismember(key, {'st','iters','nu','step'})
        S.(key) = val;  i = i + 1;
    else
        n = val;  v = zeros(n,1);
        for k = 1:n, v(k) = str2double(txt{i+k}); end
        S.(key) = v;  i = i + n + 1;
    end
end
end

function t = tern(c,a,b), if c, t=a; else, t=b; end, end
