function animateSol6(t, X, U, cfg, opt)
%ANIMATESOL6  6自由度の状態履歴を animate6DoF (機体3D表示) で再生する.
%
%   ANIMATESOL6(T, X, U, CFG)         計画解・閉ループログ共用のアダプタ
%   ANIMATESOL6(T, X, U, CFG, OPT)    OPT は animate6DoF にそのまま渡す
%                                     (saveGif, gifFile, speed, fps, orbit)
%
%   T   1xN 時刻 [s]
%   X   14xN 状態 (物理単位: [r_I(3); v_B(3); q(4); w_B(3); m(kg)])
%   U   7xN  制御 (無次元: [T_B(3)/Fs; flap(4)]) — N より短ければ末尾を保持
%
%   使い方:
%     S = load('drivers/results/landing_vert.mat');
%     animateSol6(S.sol.t, [S.sol.r; S.sol.v; S.sol.q; S.sol.w; S.sol.m], ...
%                 S.sol.uhat, S.cfg)
%
%   See also ANIMATE6DOF, RUNSCPLANDING
if nargin < 5, opt = struct(); end
N = numel(t);
if size(U,2) < N, U = [U, repmat(U(:,end), 1, N-size(U,2))]; end

P.t = t(:).';
P.y = X(3,:);                     %% ダウンレンジ
P.h = X(1,:);                     %% 高度
th = zeros(1,N);  vy = zeros(1,N);  vh = zeros(1,N);
for k = 1:N
    q = X(7:10,k)/norm(X(7:10,k));
    q0=q(1); q1=q(2); q2=q(3); q3=q(4);
    R = [1-2*(q2*q2+q3*q3),   2*(q1*q2+q0*q3),   2*(q1*q3-q0*q2);
           2*(q1*q2-q0*q3), 1-2*(q1*q1+q3*q3),   2*(q2*q3+q0*q1);
           2*(q1*q3+q0*q2),   2*(q2*q3-q0*q1), 1-2*(q1*q1+q2*q2)];
    nose = R.'*[1;0;0];                       %% 機首方向 (慣性系)
    th(k) = atan2(nose(3), nose(1));          %% 鉛直からの面内傾き
    rdI = R.'*X(4:6,k);                       %% 慣性系速度
    vh(k) = rdI(1);  vy(k) = rdI(3);
end
P.theta = th;  P.vy = vy;  P.vh = vh;
P.omega = X(12,:);                            %% ピッチ角速度 (表示用)
P.m = X(14,:);
P.throttle = min(1, max(0, vecnorm(U(1:3,:)) / (cfg.veh.thrustPerEng/cfg.Fs)));
P.gimbal = atan2(U(3,:), max(U(1,:), 1e-3));
P.df = tanh(U(4,:)/deg2rad(20));
%% 機体スタイル: 'starship' (フラップ付き) / 'falcon9' (ランディングギア付き)
style = 'starship';
if isfield(opt,'style') && ~isempty(opt.style), style = opt.style; end
if strcmp(style,'falcon9')
    animateFalcon9(P, cfg, opt);
else
    animate6DoF(P, cfg, opt);
end
end
