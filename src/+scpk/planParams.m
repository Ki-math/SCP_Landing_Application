function [pp,qpp] = planParams(opt, trX, trU, trSig)
%PLANPARAMS  planOptions6 の opt から planIterEmb 用の数値パラメータ構造体を作る.
%
%   [PP,QPP] = PLANPARAMS(OPT, TRX, TRU, TRSIG)
%   TRX/TRU/TRSIG は現在のトラストリージョン幅 (SCP反復ごとに縮む).
%
%   See also SCPK.PLANITEREMB, SCPK.PLANOPTIONS6
gf = @(f,d) getFieldDef(opt,f,d);
pp.tolPos = opt.tol.pos;   pp.tolVel = opt.tol.vel;   pp.tolQuat = opt.tol.quat;
pp.tolRate = opt.tol.rate; pp.tolMass = opt.tol.mass; pp.tolThr = opt.tol.thr;
pp.tolFlap = opt.tol.flap; pp.tolSig = opt.tol.sig;
pp.wFuel = opt.wFuel;  pp.lamVC = opt.lamVC;  pp.lamTerm = opt.lamTerm;
pp.lamGlide = gf('lamGlide', opt.lamTerm);
pp.reg = opt.reg;
pp.trX = trX;  pp.trU = trU;  pp.trSig = trSig;
smn = opt.sigMin(:).';  smx = opt.sigMax(:).';
if isscalar(smn), smn = smn*ones(1,4); end
if isscalar(smx), smx = smx*ones(1,4); end
pp.sigMin = smn;  pp.sigMax = smx;
pp.hMargin = opt.hMargin;  pp.phaseTight = opt.phaseTight;
pp.wMaxFlip = opt.wMaxFlip;  pp.wMaxTight = opt.wMaxTight;
pp.tiltMax = opt.tiltMax;  pp.glideSlope = opt.glideSlope;
pp.nCone = opt.nCone;  pp.coneHalf = opt.coneHalf;
pp.coneShrink = opt.coneShrink;  pp.lcTol = opt.lcTol;
pp.bellyHold = gf('bellyHold', 0);
qb = gf('qBelly', [1;0;0;0]);  pp.qBelly = qb(:);
pp.softGlide = double(gf('softGlide', false));
pp.monoDescent = double(gf('monoDescent', false));
db = gf('drBox', []);
if isempty(db), pp.useDrBox = 0;  pp.drBox = [0 0]; else, pp.useDrBox = 1;  pp.drBox = db(:).'; end
pp.crMax = gf('crMax', 0);
pp.thrMaxTight = gf('thrMaxTight', 0);
pp.wTilt = gf('wTilt', 0);
pp.wFlap = gf('wFlap', 0);
pp.rateLim = double(gf('rateLim', true));

qpp = struct('maxIter',opt.qp.maxIter, 'fixedIter',double(opt.qp.fixedIter), ...
    'tolPri',opt.qp.tolPri, 'tolDua',opt.qp.tolDua, 'omega',opt.qp.omega, ...
    'rho',opt.qp.rho, 'checkEvery',opt.qp.checkEvery, 'powerIter',opt.qp.powerIter, ...
    'certAfter',opt.qp.certAfter, 'certTol',opt.qp.certTol, 'certEps',opt.qp.certEps);
end

function v = getFieldDef(s,f,d)
if isfield(s,f) && ~isempty(s.(f)), v = s.(f); else, v = d; end
end
