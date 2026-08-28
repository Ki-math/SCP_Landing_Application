function [f,A,B] = dynamics6(x,u,cfg,wB)
%DYNAMICS6  スターシップ帰還の6自由度ダイナミクス (14状態) とヤコビアン.
%
%   [F,A,B] = DYNAMICS6(X,U,CFG) は無次元化された状態微分 F と, 状態/制御に
%   関するヤコビアン A = df/dx, B = df/du を返す.
%   [F,...] = DYNAMICS6(X,U,CFG,WB) は機体系風速 WB (無次元, 3x1) を与える.
%   空力は対気相対速度 v_rel = v_B - WB で評価される (省略時は無風).
%
%   大気: cfg.atmIsa=1 のとき密度は ISA 標準大気 (パッド標高 cfg.hPad + 高度)
%   に従い, 空力係数の基準密度 cfg.rho との比で全空力項をスケールする.
%   cfg.atmIsa=0 では一定密度 (従来どおり).
%
%   状態 (14)   X = [r_I(3); v_B(3); q(4); w_B(3); mhat]
%     r_I  慣性系位置 [高度; クロスレンジ; ダウンレンジ]
%     v_B  機体軸速度  (プラントのセンサバスと同じ規約なので変換不要)
%     q    四元数 スカラー先頭, R(q) は慣性 -> 機体 (Reb, smLanderModel と同じ)
%     w_B  機体軸角速度
%     mhat 質量 / m0
%
%   制御 (7)    U = [T_B(3); d_fr; d_fl; d_rr; d_rl]
%     T_B  機体軸推力ベクトル. スロットルとジンバル角は配分則で作る
%     d_*  フラップ舵角 (トリムからの偏差, 正規化)
%
%   運動方程式
%     rdot_I = R(q)' * v_B
%     vdot_B = (T_B + Faero_B)/mhat - w x v_B + R(q)*g_I
%     qdot   = 0.5 * q (x) [0; w_B]
%     wdot_B = J^-1 * (r_T x T_B + Maero_B - w x (J*w))
%     mdot   = -alpha * ||T_B||
%
%   ヤコビアンは中心差分で求める. 14x14 + 14x7 で 42 回の関数評価が要るが,
%   1 回の評価が数百 flop なので N=15 でも SCP 反復あたり数十 kflop で済む.
%   解析ヤコビアンは四元数と空力が絡むと導出量が多く誤りやすいため, まず
%   差分で正しさを担保する. コストが支配的になれば後で置き換える.
if nargin < 4, wB = nan(3,1); end   %% NaN = cfg の風テーブルを使用 (計画/追従経路).
                                    %% プラントは wB を明示指定して風を与える.
f = dyn(x,u,cfg,wB);
if nargout > 1
    nx = numel(x);  nu = numel(u);
    A = zeros(nx,nx);  B = zeros(nx,nu);
    hx = cfg.jacStep;
    for i = 1:nx
        e = zeros(nx,1);  e(i) = hx;
        A(:,i) = (dyn(x+e,u,cfg,wB) - dyn(x-e,u,cfg,wB))/(2*hx);
    end
    for i = 1:nu
        e = zeros(nu,1);  e(i) = hx;
        B(:,i) = (dyn(x,u+e,cfg,wB) - dyn(x,u-e,cfg,wB))/(2*hx);
    end
end
end


function f = dyn(x,u,cfg,wB)
%DYN  状態微分の本体.
v = x(4:6);  q = x(7:10);  w = x(11:13);  mh = max(x(14), cfg.mhatMin);
T = u(1:3);  d = u(4:7);

%% --- 回転行列 R(q): 慣性 -> 機体 ---
q0=q(1); q1=q(2); q2=q(3); q3=q(4);
R = [1-2*(q2*q2+q3*q3),   2*(q1*q2+q0*q3),   2*(q1*q3-q0*q2);
       2*(q1*q2-q0*q3), 1-2*(q1*q1+q3*q3),   2*(q2*q3+q0*q1);
       2*(q1*q3+q0*q2),   2*(q2*q3-q0*q1), 1-2*(q1*q1+q2*q2)];

%% --- 風 (wB=NaN のとき cfg の風テーブルから計算: 計画・追従MPC用) ---
%% 既知の風況を計画モデルに入れることで, コースト等の制御力が無い区間の
%% 風ドリフトをフィードフォワードで織り込む (残差はフィードバックが吸収).
if any(isnan(wB))
    wB = zeros(3,1);
    if cfg.wOn > 0
        hq = min(max(x(1)*cfg.sc.L, cfg.wTabH(1)), cfg.wTabH(8));
        wy = cfg.wTabY(8);  wz = cfg.wTabZ(8);
        for ii = 1:7
            if hq <= cfg.wTabH(ii+1)
                ss = (hq - cfg.wTabH(ii))/max(cfg.wTabH(ii+1)-cfg.wTabH(ii), 1e-9);
                wy = cfg.wTabY(ii) + ss*(cfg.wTabY(ii+1)-cfg.wTabY(ii));
                wz = cfg.wTabZ(ii) + ss*(cfg.wTabZ(ii+1)-cfg.wTabZ(ii));
                break;
            end
        end
        wB = R*([0; wy; wz]/cfg.sc.V);   %% 慣性系風 -> 機体系 (無次元)
    end
end
va = v - wB;                       %% 対気相対速度 (空力のみに使用)

%% --- 空力 (機体軸成分ごとの抗力 + フラップ. 対気速度 va で評価) ---
V2 = va(1)*va(1) + va(2)*va(2) + va(3)*va(3);
V  = sqrt(V2 + cfg.vEps);
%% 大気密度比: ISA (cfg.atmIsa=1) なら 高度に応じて rhoISA/cfg.rho を乗じる
if cfg.atmIsa > 0
    hgeo = cfg.hPad + x(1)*cfg.sc.L;
    hc = min(max(hgeo, 0), 11000);
    fRho = 1.225*((288.15 - 0.0065*hc)/288.15)^4.2561 / cfg.rho;
else
    fRho = 1;
end
%% 成分抗力: 各機体軸の速度成分に比例. 一様円柱なので CG まわりのモーメントは持たない
Fa = -fRho*[cfg.cx*V*va(1); cfg.cy*V*va(2); cfg.cz*V*va(3)];
%% 揚力は別項として足さない. 成分抗力 -[cx*V*vx; cy*V*vy; cz*V*vz] は
%% cx ~= cy のとき合力が速度と平行にならず, その垂直成分が揚力になる.
%% 迎角ちょうど 90deg では vx=0 で揚力が消えるが, これは対称な円柱として
%% 物理的に正しい. 実機も迎角を 90deg から外して揚力を得る.
%% 操縦翼面. cfg.surfMode で機体のデバイスを切替:
%%   1 = ベリーフラップ (Starship): 迎角依存 |sin(alpha)| で減衰
%%       (テールダウンでは流れに沿うので効きが消える)
%%   2 = グリッドフィン (Falcon9): 軸流でも効く (迎角依存なし)
if cfg.surfMode >= 2
    qs = fRho*V2/cfg.V2ref;
else
    sa = sqrt(va(2)*va(2) + va(3)*va(3))/V;
    qs = fRho*(V2/cfg.V2ref) * sa;
end
Fa(1) = Fa(1) - cfg.cFlapDrag*qs*V*sign(va(1))*abs(va(1))/max(V,cfg.vEps);
Ma = cfg.Bflap*d * qs;

%% --- 推力 ---
nT = sqrt(T(1)*T(1) + T(2)*T(2) + T(3)*T(3) + cfg.tEps);
Mt = cross(cfg.rT, T);

%% --- 微分 ---
f = zeros(14,1);
f(1:3)   = R.'*v;
f(4:6)   = (T + Fa)/mh - cross(w,v) + R*cfg.gI;
f(7)     = -0.5*(q1*w(1) + q2*w(2) + q3*w(3));
f(8)     =  0.5*(q0*w(1) + q2*w(3) - q3*w(2));
f(9)     =  0.5*(q0*w(2) + q3*w(1) - q1*w(3));
f(10)    =  0.5*(q0*w(3) + q1*w(2) - q2*w(1));
%% フラップの寄与 Ma は実測同定が角加速度なので Jinv を通さず直接加える.
%% モーメント扱いすると Jinv (対角 3073) 倍だけ過大になる.
f(11:13) = cfg.Jinv*(Mt - cross(w, cfg.J*w)) + Ma;
f(14)    = -cfg.alpha*nT;
end





