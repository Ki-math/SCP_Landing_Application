function [f,A,B,Bs] = dynamics(x,u,s,cfg)
%DYNAMICS  平面6-DoF ダイナミクス. ヤコビアンは中心差分 (h=1e-6, 精度 ~1e-10).
f = scp6f(x,u,s,cfg);
if nargout > 1
    h = 1e-6; nx = numel(x); nu = numel(u);
    A = zeros(nx,nx);
    for i = 1:nx
        e = zeros(nx,1); e(i) = h;
        A(:,i) = (scp6f(x+e,u,s,cfg) - scp6f(x-e,u,s,cfg))/(2*h);
    end
    B = zeros(nx,nu);
    for i = 1:nu
        e = zeros(nu,1); e(i) = h;
        B(:,i) = (scp6f(x,u+e,s,cfg) - scp6f(x,u-e,s,cfg))/(2*h);
    end
    Bs = (scp6f(x,u,s+h,cfg) - scp6f(x,u,s-h,cfg))/(2*h);
end
end

function f = scp6f(x,u,s,cfg)
vx = x(3); vz = x(4); th = x(5); om = x(6); mh = max(x(7),1e-3);
Tx = u(1); Tz = u(2); df = u(3);
c = cos(th); sn = sin(th);
V = sqrt(vx^2 + vz^2 + 1e-9);
vBx =  c*vx + sn*vz;          % 機体軸系での速度成分
vBz = -sn*vx + c*vz;
% 成分抗力 (一様円柱なので CG まわりのモーメントは持たない)
% 成分抗力 + フラップの軸方向抗力 (プラント実測で同定, 対称舵角トリム固定).
% smLanderModel.mlx は Force_b(1)=0 としているが実機プラントは軸方向力を出す.
aFl = cfg.cFlapDrag*abs(vBz)*cfg.flapTrim^2;   % |sin(alpha)| 依存: テールダウンでは消える
FBx = -cfg.cx*V*vBx - aFl*vBx;
FBz = -cfg.cy*V*vBz - aFl*vBz;
TIx = Tx*c - Tz*sn;   TIz = Tx*sn + Tz*c;      % 慣性系へ回転
FIx = FBx*c - FBz*sn; FIz = FBx*sn + FBz*c;
ax = (TIx + FIx)/mh + cfg.g;
az = (TIz + FIz)/mh;
% プラント整合: My = r1x*Fz - T_1基  (ジンバル中立でも -T のバイアスが残る)
% 符号対応: 本モデルの theta は機体軸を鉛直上向きから +ダウンレンジ方向へ測る.
% 尾部に働く +b_z 方向の力は機首を -b_z へ回すので, 正の Tz は負の omd を生む.
% プラントの My 符号とは逆対応 (plant_My = -k*omd). よってバイアス -T は +cB*Tx.
omd = -cfg.cT*Tz + cfg.cB*Tx + cfg.cf*V*vBz*df;
f = [vx; vz; ax; az; om; omd; -cfg.alpha*s];
end



