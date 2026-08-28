function [prob,optQP] = buildTrackProb(xcPhys, tNow, ref, cfg, topt)
%BUILDTRACKPROB  track6Step と同じ構成の追従QPを単体で組む (計測/検証用).
%
%   [PROB,OPTQP] = BUILDTRACKPROB(XCPHYS,TNOW,REF,CFG,TOPT)
%
%   XCPHYS 現在状態 (物理単位 14), TNOW 参照時間軸上の現在時刻 [s]
%   REF    計画解 (plan6ft の sol 互換: t, xhat, uhat, engSched)
%   PROB   solveQP / solveQPC に渡せる密QP構造体
%
%   See also SCPK.TRACK6STEP, BUILDPIPG, CODEGENQP
sc = cfg.sc;  nx = 14;  nu = 7;  H = topt.H;  dtau = topt.dt/sc.T;
sx = [repmat(sc.L,3,1); repmat(sc.V,3,1); ones(4,1); repmat(1/sc.T,3,1); cfg.m0];
xc = xcPhys(:)./sx;
tk = min(tNow + (0:H)*topt.dt, ref.t(end));
xr = interp1(ref.t, ref.xhat.', tk, 'linear', 'extrap').';
tu = ref.t(1:size(ref.uhat,2));
ur = interp1(tu, ref.uhat.', tk(1:H), 'previous', 'extrap').';
if size(ur,1) ~= nu, ur = ur.'; end
engk = interp1(tu, ref.engSched(:), tk(1:H), 'previous', 'extrap').';
t = topt.tol;
Dx = [repmat(t.pos/sc.L,3,1); repmat(t.vel/sc.V,3,1); repmat(t.quat,4,1); ...
      repmat(deg2rad(t.rate)*sc.T,3,1); t.mass/cfg.m0];
Du = [repmat(t.thr/cfg.Fs,3,1); repmat(t.flap,4,1)];
wx = [repmat(topt.wPos,3,1); repmat(topt.wVel,3,1); repmat(topt.wQuat,4,1); ...
      repmat(topt.wRate,3,1); topt.wMass];
ix = reshape(1:nx*H,nx,H);  iu = nx*H + reshape(1:nu*H,nu,H);  nz = nx*H+nu*H;
P = diag([repmat(wx,H,1); repmat(topt.rCtrl*ones(nu,1),H,1)]);
P(ix(:,H),ix(:,H)) = P(ix(:,H),ix(:,H))*topt.wTerm;  P = P + topt.reg*eye(nz);
q = zeros(nz,1);
G = zeros(nx*H,nz);  g = zeros(nx*H,1);
dxc = (xc - xr(:,1))./Dx;
for k2 = 1:H
    [f,A,B] = scpk.dynamics6(xr(:,k2), ur(:,k2), cfg);
    c = f - A*xr(:,k2) - B*ur(:,k2);
    [Ad,Bd,cd] = scpk.discretize(A,B,c,dtau);
    dk = (Ad*xr(:,k2) + Bd*ur(:,k2) + cd - xr(:,k2+1))./Dx;
    r = nx*(k2-1)+(1:nx);
    G(r,ix(:,k2)) = eye(nx);
    if k2 == 1, g(r) = diag(1./Dx)*Ad*diag(Dx)*dxc + dk;
    else, G(r,ix(:,k2-1)) = -diag(1./Dx)*Ad*diag(Dx);  g(r) = dk; end
    G(r,iu(:,k2)) = -diag(1./Dx)*Bd*diag(Du);
end
lb = -inf(nz,1);  ub = inf(nz,1);
for k2 = 1:H
    Tmax = engk(k2)*cfg.Tmax1;  Tmin = engk(k2)*cfg.Tmin1;
    lb(iu(1,k2)) = (Tmin-ur(1,k2))/Du(1);  ub(iu(1,k2)) = (Tmax-ur(1,k2))/Du(1);
    Tlat = Tmax*sin(cfg.veh.tvcMax);
    lb(iu(2,k2)) = (-Tlat-ur(2,k2))/Du(2); ub(iu(2,k2)) = (Tlat-ur(2,k2))/Du(2);
    lb(iu(3,k2)) = (-Tlat-ur(3,k2))/Du(3); ub(iu(3,k2)) = (Tlat-ur(3,k2))/Du(3);
    for i = 4:7
        lb(iu(i,k2)) = (-cfg.veh.flapTrim-ur(i,k2))/Du(i);
        ub(iu(i,k2)) = ((cfg.veh.flapMax-cfg.veh.flapTrim)-ur(i,k2))/Du(i);
    end
    if engk(k2) == 0
        lb(iu(1:3,k2)) = (0-ur(1:3,k2))./Du(1:3);  ub(iu(1:3,k2)) = lb(iu(1:3,k2));
    end
end
prob = struct('P',P,'q',q,'G',G,'g',g,'A',zeros(0,nz),'b',zeros(0,1),'lb',lb,'ub',ub);
optQP = topt.qp;
end
