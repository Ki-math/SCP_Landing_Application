function out = codegenPlanIter()
%CODEGENPLANITER  GNCコア (計画SCP 1反復 + 追従MPC 1周期) のフルC生成 + 検証.
%
%   2つのエントリポイントを型を共有して1つの lib に生成する:
%     scpk.planIterEmb  計画SCP 1反復 (オンライン再計画/フル計画)
%     scpk.trackStepEmb 追従MPC 1周期 (LTV追従QP)
%   それぞれ独立に呼べるため, 部品としての単体利用も, 両方を組み合わせた
%   誘導制御ループの構築も可能. MEX も各々生成する.
%
%   See also SCPK.PLANITEREMB, SCPK.TRACKSTEPEMB, SCPCODEGENZIP
here = fileparts(mfilename('fullpath'));  proj = fileparts(here);
cpp = fullfile(proj,'src','cpp');
addpath(fullfile(proj,'src'), cpp);
cd(cpp);
cfg = scpk.model6();
opt0 = scpk.planOptions6();  opt0.softGlide = true;
[pp0,qp0] = scpk.planParams(opt0, 20, 10, 2);
tp0 = scpk.trackParams(scpk.track6Options(), cfg);

%% --- 型 (可変サイズ) ---
a = { coder.typeof(0,[14 1]), coder.typeof(0,[12 1]), ...
      coder.typeof(0,[14 201],[0 1]), coder.typeof(0,[7 200],[0 1]), ...
      coder.typeof(0,[1 200],[0 1]),  coder.typeof(0,[1 8],[0 1]), ...
      coder.typeof(0,[1 200],[0 1]),  coder.typeof(0,[1 200],[0 1]), ...
      coder.typeof(0,[1 200],[0 1]),  coder.typeof(0,[1 201],[0 1]), ...
      coder.typeof(cfg), coder.typeof(pp0), coder.typeof(qp0), ...
      coder.typeof(0,[12000 1],[1 0]) };

%% --- 追従MPCの型 (可変ホライズン H<=60) ---
aT = { coder.typeof(0,[14 1]), coder.typeof(0,[14 61],[0 1]), ...
       coder.typeof(0,[7 60],[0 1]), coder.typeof(0,[1 60],[0 1]), ...
       coder.typeof(cfg), coder.typeof(tp0), coder.typeof(0,[1300 1],[1 0]) };

mc = coder.config('mex');
codegen('-config',mc,'scpk.planIterEmb','-args',a, ...
        '-d',fullfile(cpp,'codegen_planiter_mex'),'-o','planIterEmb_mex');
fprintf('MEX 生成 OK (planIterEmb)\n');
codegen('-config',mc,'scpk.trackStepEmb','-args',aT, ...
        '-d',fullfile(cpp,'codegen_trackstep_mex'),'-o','trackStepEmb_mex');
fprintf('MEX 生成 OK (trackStepEmb)\n');
lc = coder.config('lib');  lc.EnableOpenMP = false;
lc.HardwareImplementation.ProdHWDeviceType = 'Intel->x86-64 (Linux 64)';
lc.GenCodeOnly = true;   % ターゲット非依存の純Cソースのみ (tmwtypes.h 非依存)
outdir = fullfile(cpp,'codegen_planiter_lib');
codegen('-config',lc,'scpk.planIterEmb','-args',a, ...
        'scpk.trackStepEmb','-args',aT,'-d',outdir,'-o','gncCore_lib');
cf = [dir(fullfile(outdir,'**','*.c')); dir(fullfile(outdir,'**','*.h'))];
hits = {};
for i=1:numel(cf)
    if ~isempty(regexpi(fileread(fullfile(cf(i).folder,cf(i).name)),'dgemm|dgemv|cblas|xgemm','once'))
        hits{end+1}=cf(i).name; %#ok<AGROW>
    end
end
fprintf('lib 生成 OK: BLAS残存 %d件 / %dファイル\n', numel(hits), numel(cf));

%% --- 等価性 + 計測 ---
S = load(fullfile(proj,'results','landing_vert.mat'));
sol=S.sol; opt=S.opt; x0=S.x0; sc=cfg.sc;
sx=[repmat(sc.L,3,1);repmat(sc.V,3,1);ones(4,1);repmat(1/sc.T,3,1);cfg.m0];
xT=[cfg.hmin;0;0;0;0;0;0;0;0;0;0;0];
dtv=arrayfun(@(j) 1/sum(opt.phase==j), opt.phase);
sh=opt.trShrinkRate^(opt.maxIter-1);
trX=max(opt.trXmin,opt.trX*sh); trU=max(opt.trUmin,opt.trU*sh); trSig=max(opt.trSigMin,opt.trSig*sh);
[pp,qpp]=scpk.planParams(setTR(opt,trX,trU,trSig), trX, trU, trSig);
args = {x0./sx, xT, sol.xhat, sol.uhat, sol.ghat, sol.sigma/sc.T, ...
        double(opt.phase), double(opt.engSched), dtv, opt.tiltMaxNode, cfg, pp, qpp};
nR=7; tC=zeros(1,nR); tW=zeros(1,nR);
z0 = zeros(0,1);
[xs,~,~,ss,st,it,nu,~,zW] = planIterEmb_mex(args{:}, z0);
for r=1:nR
    t1=tic; planIterEmb_mex(args{:}, zeros(0,1)); tC(r)=toc(t1);
    t2=tic; [~,~,~,~,st2,it2] = planIterEmb_mex(args{:}, zW); tW(r)=toc(t2);
end
fprintf('等価性: st=%d it=%d nu=%.1e sigma=[%s]\n', st, it, nu, num2str(ss*sc.T,'%.2f '));
fprintf('1反復フルC: cold %.1f ms (%d回) | warm %.1f ms (%d回)\n', ...
    median(tC)*1e3, it, median(tW)*1e3, it2);

%% --- 追従MPC MEX の等価性 + 計測 ---
topt = scpk.track6Options();
refD = scpk.densify6(sol, cfg, min(0.1, topt.dt/2));
tp = scpk.trackParams(topt, cfg);
H = topt.H;
tk = min(2.0 + (0:H)*topt.dt, refD.t(end));
xr = interp1(refD.t, refD.xhat.', tk, 'linear','extrap').';
tu = refD.t(1:size(refD.uhat,2));
ur = interp1(tu, refD.uhat.', tk(1:H), 'previous','extrap').';
if size(ur,1) ~= 7, ur = ur.'; end
for k = 1:H+1
    nq = norm(xr(7:10,k));  if nq > eps, xr(7:10,k) = xr(7:10,k)/nq; end
end
engk = interp1(tu, refD.engSched(:), tk(1:H), 'previous','extrap');
engk = reshape(engk, 1, []);
xcP = xr(:,1).*sx;
zt = zeros(21*H,1);
[uM,zM] = scpk.trackStepEmb(xcP, xr, ur, engk, cfg, tp, zt);
[uX,zX] = trackStepEmb_mex(xcP, xr, ur, engk, cfg, tp, zt);
dTrk = max(abs(uM-uX));
tT = zeros(1,nR);
for r = 1:nR
    t3 = tic;  trackStepEmb_mex(xcP, xr, ur, engk, cfg, tp, zX);  tT(r) = toc(t3);
end
fprintf('追従MPC: MEX等価性 max|du|=%.1e | 1周期 %.1f ms\n', dTrk, median(tT)*1e3);

out = struct('tCold',median(tC),'tWarm',median(tW),'itCold',it,'itWarm',it2, ...
             'tTrack',median(tT),'dTrack',dTrk,'blasHits',{hits});
save(fullfile(proj,'results','codegenPlanIter.mat'),'-struct','out');
fprintf('保存: results/codegenPlanIter.mat\n');
fp = mexFingerprint();  save(fullfile(proj,'results','mex_fingerprint.mat'),'fp'); %#ok<NASGU>
end

function o = setTR(o,x,u,s), o.trX=x; o.trU=u; o.trSig=s; end
