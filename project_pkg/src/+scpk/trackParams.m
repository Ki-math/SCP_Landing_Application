function tp = trackParams(topt, cfg)
%TRACKPARAMS  追従MPC (trackStepEmb) の実行時パラメータ構造体を組む.
%
%   TP = TRACKPARAMS(TOPT, CFG)  track6Options の設定を codegen 向けの
%   フラットな数値構造体に変換する (生成コードは構造体レイアウトに厳密).
%
%   See also SCPK.TRACKSTEPEMB, SCPK.TRACK6OPTIONS, CODEGENTRACKSTEP
sc = cfg.sc;  t = topt.tol;
tp.dtau = topt.dt/sc.T;
tp.Dx = [repmat(t.pos/sc.L,3,1); repmat(t.vel/sc.V,3,1); repmat(t.quat,4,1); ...
         repmat(deg2rad(t.rate)*sc.T,3,1); t.mass/cfg.m0];
tp.Du = [repmat(t.thr/cfg.Fs,3,1); repmat(t.flap,4,1)];
tp.wx = [repmat(topt.wPos,3,1); repmat(topt.wVel,3,1); repmat(topt.wQuat,4,1); ...
         repmat(topt.wRate,3,1); topt.wMass];
tp.rCtrl = topt.rCtrl;
tp.wTerm = topt.wTerm;
tp.reg   = topt.reg;
%% QP (PIPG) 設定. fastQP なら固定反復 (決定的)
qp = topt.qp;
tp.maxIter    = double(qp.maxIter);
tp.fixedIter  = 0;
if isfield(topt,'fastQP') && topt.fastQP
    tp.maxIter = 300;  tp.fixedIter = 1;
end
tp.tolPri     = qp.tolPri;
tp.tolDua     = qp.tolDua;
tp.omega      = qp.omega;
tp.rho        = qp.rho;
tp.checkEvery = double(qp.checkEvery);
tp.powerIter  = double(qp.powerIter);
end
