function ok = verifyEmbedded()
%VERIFYEMBEDDED  組み込みパッケージの等価性検証 (コンパイル済みC vs MATLAB参照).
%
%   OK = VERIFYEMBEDDED() は次を自動実行する:
%     1. scp_landing_embedded.zip を一時フォルダへ展開
%     2. MinGW gcc で examples/main_verify.c をビルド (実機と同じ純Cソース)
%     3. 実行し, 計画SCP 1反復と追従MPC 1周期の結果をファイル取得
%     4. MATLAB参照実装 (scpk.planIterEmb / scpk.trackStepEmb) を
%        同一入力 (results/plan_example_args.mat) で実行
%     5. 数値一致を突き合わせ (状態軌道/制御/σ/u0/姿勢コマンド/QP状態)
%
%   判定閾値: 軌道・制御 1e-6 (無次元), 参照窓 1e-9, QP status/iters は一致.
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

fprintf('\n=== 等価性検証: コンパイル済みC (gcc -O2) vs MATLAB参照実装 ===\n');
ok = true;
for i = 1:size(res,1)
    fprintf('  [%s] %-42s max|diff| = %.2e\n', tern(res{i,3},'OK','NG'), res{i,1}, res{i,2});
    ok = ok && res{i,3};
end
fprintf('=== 総合判定: %s ===\n', tern(ok,'PASS (数値一致)','FAIL'));
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
