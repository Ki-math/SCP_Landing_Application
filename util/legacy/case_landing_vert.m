function [sol,cfg,x0,opt] = case_landing_vert(quick)
%CASE_LANDING_VERT  最終形の着陸計画 (遅フリップ・L字軌道) の再現ドライバ.
%
%   [SOL,CFG,X0,OPT] = CASE_LANDING_VERT()      フル再現 (コールド+ウォーム3段, 約2-3分)
%   [SOL,CFG,X0,OPT] = CASE_LANDING_VERT(true)  保存済み landing_vert.mat を読むだけ
%
%   シナリオ: 高度1200 m, ダウンレンジ -325 m, ベリーフロップ, 降下80 m/s.
%   構造    : ベリーで476 mまで自由落下 -> 4秒フリップ -> 1基ブレーキ -> 垂直降下.
%   結果    : 終端 高度34 m(目標31)・水平0.5 m・|v|3.3 m/s・直立, nu=0, 燃料22.6 t.
%
%   数式・定式化の説明は docs/SCP_formulation.md を参照.
%
%   See also SCPK.PLAN6FT, RUNSCPLANDING
here = fileparts(mfilename('fullpath'));  proj = fileparts(fileparts(here));  addpath(fullfile(proj,'src'), fullfile(proj,'src','cpp'));
resf = fullfile(proj,'results','landing_vert.mat');
if nargin >= 1 && quick && exist(resf,'file')
    S = load(resf);  sol = S.sol;  cfg = S.cfg;  x0 = S.x0;  opt = S.opt;
    fprintf('保存済み計画を読み込み: tf=%.1fs 燃料%.1ft\n', sol.tf, sol.propellant/1e3);
    return
end

cfg = scpk.model6();
qBelly = eul2quat([0 -pi/2 0],'ZYX').';
vB0 = quat2dcm(qBelly.')*[-80;0;0];
x0 = [1200; 0; -325; vB0; qBelly; 0;0;0; cfg.m0];
xT = [cfg.hmin; 0;0; 0;0;0; 0;0;0; 0;0;0];

%% フェーズ構成: 空力降下(12) フリップ(10) ブレーキ(12) 精密着陸(16), 基数 0-3-1-1
phase = [1*ones(1,12), 2*ones(1,10), 3*ones(1,12), 4*ones(1,16)];  N = numel(phase);
eng   = [0*ones(1,12), 3*ones(1,10), 1*ones(1,12), 1*ones(1,16)];

%% 傾斜角スケジュール (タンブリング防止): P2 100->30, P3 30->10, P4 10 deg
tiltN = deg2rad(179)*ones(1,N+1);
i2 = find(phase==2);  tiltN(i2(1):i2(end)+1) = deg2rad(linspace(100,30,numel(i2)+1));
i3 = find(phase==3);  tiltN(i3(1):i3(end)+1) = deg2rad(linspace(30,10,numel(i3)+1));
i4 = find(phase==4);  tiltN(i4(1):N+1) = deg2rad(10);

opt = scpk.planOptions6();
opt.phase = phase;  opt.engSched = eng;
opt.qBelly = qBelly;  opt.bellyHold = 2;
opt.softGlide = true;               % グライドスロープはソフト (実行可能性の担保)
opt.tiltMaxNode = tiltN;            % 傾斜角はハード (姿勢の物理を守る)
opt.wMaxFlip = deg2rad(30);  opt.wMaxTight = deg2rad(10);
opt.sigMin = [8 3 2 4];  opt.sigMax = [10 4 5 20];
opt.lamTerm = 2e6;  opt.lamGlide = 2e5;
opt.thrMaxTight = 0.9;  opt.phaseTight = 4;
opt.trShrinkRate = 0.93;  opt.trXmin = 3;  opt.trUmin = 2;  opt.trSigMin = 0.3;
opt.maxIter = 24;  opt.qp.maxIter = 6000;  opt.tolStep = 1e-3;
opt.wFuel = 15;  opt.verbose = true;

%% --- pass 1: コールドスタート ---
fprintf('=== pass1: cold start ===\n');
[sol,~] = scpk.plan6ft(x0, xT, [9 3.5 4 10], cfg, opt);

%% --- pass 2: 単調降下+行き過ぎ防止を追加してウォームスタート ---
fprintf('=== pass2: +monoDescent +drBox ===\n');
opt.monoDescent = true;  opt.drBox = [-380 10];  opt.crMax = 40;
opt.lamTerm = 1e7;  opt.sigMax = [10 4 5 26];  opt.maxIter = 14;  opt.tolStep = 8e-4;
[sol,~] = scpk.plan6ft(x0, xT, sol.sigma, cfg, opt, sol);

%% --- pass 3: 終端を締める ---
fprintf('=== pass3: tighten terminal ===\n');
opt.lamTerm = 5e7;  opt.sigMax = [10 4 5 34];  opt.wFuel = 25;  opt.maxIter = 12;  opt.tolStep = 6e-4;
[sol,~] = scpk.plan6ft(x0, xT, sol.sigma, cfg, opt, sol);

%% --- pass 4: 最終詰め ---
fprintf('=== pass4: final ===\n');
opt.lamTerm = 1e8;  opt.sigMax = [10 4 5 40];  opt.maxIter = 10;
[sol,~] = scpk.plan6ft(x0, xT, sol.sigma, cfg, opt, sol);

rE = sol.r(:,end);  rd = quat2dcm(sol.q(:,end).').'*sol.v(:,end);
fprintf('\n終端: 高度%.1fm 水平%.1fm |v|%.2f 傾斜%.1fdeg 燃料%.1ft tf=%.1fs nu=%.1e\n', ...
    rE(1), hypot(rE(2),rE(3)), norm(rd), ...
    acosd(max(-1,1-2*(sol.q(3,end)^2+sol.q(4,end)^2))), sol.propellant/1e3, sol.tf, sol.virtCtrl);
save(resf, 'sol','cfg','x0','opt');
fprintf('保存: %s\n', resf);
end
