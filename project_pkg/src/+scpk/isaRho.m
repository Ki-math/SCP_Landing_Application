function rho = isaRho(h) %#codegen
%ISARHO  ISA標準大気の密度 [kg/m^3] (対流圏 0-11 km, それ以上はクランプ).
%
%   RHO = ISARHO(H)  H: ジオポテンシャル高度 [m] (スカラーまたは配列)
%
%   ISA (International Standard Atmosphere):
%     T = 288.15 - 0.0065*h [K],  rho = 1.225*(T/288.15)^4.2561
%
%   See also SCPK.DYNAMICS6, SCPK.MODEL6
hc = min(max(h, 0), 11000);
T  = 288.15 - 0.0065*hc;
rho = 1.225*(T/288.15).^4.2561;
end
