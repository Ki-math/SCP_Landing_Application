function [f,A,B] = dynamics6Paper(x,u,cfg)
%DYNAMICS6PAPER  Lee, Jung & Lee (2025) の6自由度ダイナミクス (Eqs.1-15) と Jacobian.
%
%   [F,A,B] = DYNAMICS6PAPER(X,U,CFG)
%   状態 X = [m; rI(3); vI(3); qB(4); wB(3)] (SI, 慣性ENU, 機体Z=機首)
%   制御 U = T_B(3) [N]
%
%   運動方程式 (論文 Eqs.1-14)
%     mdot   = -||T||/(g0*Isp)                                   (Eq.3)
%     rdot_I = vI                                               (Eq.1)
%     vdot_I = (1/m)*CIB*(T + AB) + gI                          (Eq.2,11)
%     qdot   = 0.5*Omega(w)*q                                   (Eq.4,6)
%     wdot   = IB^-1*(MB - w x IB w)                            (Eq.5)
%   ここで AB = -0.5*rho*SA*||vB||*CA*vB (楕円体空力, Eq.14),
%   MB = rT x T + rA x AB. ただし空力降下 (T=0) はフラップが空力モーメントを
%   相殺する仮定 (論文2.2.2) のため MB=0 とする.
%
%   See also SCPK.MODEL6PAPER
f = dynP(x,u,cfg);
if nargout > 1
    n = 14;  nu = 3;  A = zeros(n,n);  B = zeros(n,nu);  h = cfg.jacStep;
    for i = 1:n
        e = zeros(n,1);  e(i) = h;
        A(:,i) = (dynP(x+e,u,cfg) - dynP(x-e,u,cfg))/(2*h);
    end
    for i = 1:nu
        e = zeros(nu,1);  e(i) = h;
        B(:,i) = (dynP(x,u+e,cfg) - dynP(x,u-e,cfg))/(2*h);
    end
end
end


function f = dynP(x,u,cfg)
m = max(x(1),cfg.mdry);  v = x(5:7);  q = x(8:11);  w = x(12:14);  T = u(1:3);
q0=q(1); q1=q(2); q2=q(3); q3=q(4);
%% CIB: 機体 -> 慣性 (論文 Eq.13)
CIB = [1-2*(q2^2+q3^2),   2*(q1*q2-q0*q3),   2*(q1*q3+q0*q2);
         2*(q1*q2+q0*q3), 1-2*(q1^2+q3^2),   2*(q2*q3-q0*q1);
         2*(q1*q3-q0*q2),   2*(q2*q3+q0*q1), 1-2*(q1^2+q2^2)];
%% 空力 (楕円体モデル, 機体系, Eq.14)
vB  = CIB.'*v;
nvB = sqrt(vB.'*vB + 1e-12);
AB  = -0.5*cfg.rho*cfg.SA*nvB*[cfg.Caxy*vB(1); cfg.Caxy*vB(2); cfg.Caz*vB(3)];
%% 並進 (Eq.2, 11)
FI = CIB*(T + AB);
gI = [0;0;-cfg.g0];
%% 慣性 (円柱近似, 現質量, Eq.8-10)
Ixx = 0.25*m*cfg.Lr^2 + (1/12)*m*cfg.Lh^2;  Iyy = Ixx;  Izz = 0.5*m*cfg.Lr^2;
%% モーメント (Eq.12). 空力降下(T=0)はフラップが相殺 -> MB=0.
nT = sqrt(T.'*T);
if nT < cfg.tEps
    MB = [0;0;0];
else
    MB = cross([0;0;-cfg.Lcm],T) + cross([0;0;cfg.Lcp],AB);
end
%% 四元数 (Eq.4, 6)
p=w(1); qq=w(2); rr=w(3);
Om = [0 -p -qq -rr;  p 0 rr -qq;  qq -rr 0 p;  rr qq -p 0];
IBw = [Ixx*w(1); Iyy*w(2); Izz*w(3)];
f = zeros(14,1);
f(1)     = -nT/(cfg.g0*cfg.Isp);
f(2:4)   = v;
f(5:7)   = FI/m + gI;
f(8:11)  = 0.5*Om*q;
f(12:14) = (MB - cross(w,IBw))./[Ixx;Iyy;Izz];
end
