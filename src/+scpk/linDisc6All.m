function [Ad,Bd,Sd,cd] = linDisc6All(xl,ul,sigl,phase,dtv,cfg) %#codegen
%LINDISC6ALL  全節点の線形化+ZOH離散化 (計画buildのホットループ, コード生成対象).
%
%   [AD,BD,SD,CD] = LINDISC6ALL(XL,UL,SIGL,PHASE,DTV,CFG)
%
%   XL 14x(N+1) 線形化点状態, UL 7xN 制御, SIGL 1xnPh 時間膨張 (無次元),
%   PHASE 1xN フェーズ番号, DTV 1xN 正規化刻み.
%   自由終端時刻: sigma を追加制御として扱い, B列に f を足す (buildPlan6 と同一).
%
%   出力: AD 14x14xN, BD 14x7xN, SD 14xN (sigma感度), CD 14xN.
%
%   コード生成: codegen scpk.linDisc6All -args {...} (drivers/codegenBuild.m 参照)
%   buildPlan6 は linDisc6All_mex があれば自動でそれを使う (単一ソース).
%
%   See also SCPK.BUILDPLAN6, SCPK.DYNAMICS6, SCPK.DISCRETIZE
nx = 14;  nu = 7;  N = size(ul,2);
Ad = zeros(nx,nx,N);  Bd = zeros(nx,nu,N);  Sd = zeros(nx,N);  cd = zeros(nx,N);
for k = 1:N
    [f,A,B] = scpk.dynamics6(xl(:,k), ul(:,k), cfg);
    sb = sigl(phase(k));
    c  = -sb*A*xl(:,k) - sb*B*ul(:,k);
    [Adk,Bk,cdk] = scpk.discretize(sb*A, [sb*B, f], c, dtv(k));
    Ad(:,:,k) = Adk;
    Bd(:,:,k) = Bk(:,1:nu);
    Sd(:,k)   = Bk(:,nu+1);
    cd(:,k)   = cdk;
end
end
