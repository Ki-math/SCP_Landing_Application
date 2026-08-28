function [sol,cfg,x0,opt] = case_landing_falcon9(quick)
%CASE_LANDING_FALCON9  Falcon9級ブースタの着陸計画 (ホバースラム) デモ.
%
%   [SOL,CFG,X0,OPT] = CASE_LANDING_FALCON9()      計画を解いて保存
%   [SOL,CFG,X0,OPT] = CASE_LANDING_FALCON9(true)  保存済み landing_falcon9.mat を読む
%
%   シナリオ: 高度2200 m, テールファースト垂直降下 240 m/s, ダウンレンジ-40 m.
%   フェーズ: コースト(0基) -> 3基ブレーキ -> 1基 -> 精密着陸(1基).
%   特徴: Merlin 1基の最低スロットルでも T/W=1.46 > 1 のためホバー不能
%         (ホバースラム). 燃焼開始タイミング自体を自由終端時刻 sigma が決める.
%
%   Starship との違いは cfg (scpk.modelFalcon9) とフェーズ/姿勢スケジュール
%   のみ. 力学エンジン・ソルバ・追従MPCは共通 (モデルプラグイン方式のデモ).
%
%   See also SCPK.MODELFALCON9, CASE_LANDING_VERT, RUN_MAIN
here = fileparts(mfilename('fullpath'));  proj = fileparts(fileparts(here));  addpath(fullfile(proj,'src'), fullfile(proj,'src','cpp'));
resf = fullfile(proj,'results','landing_falcon9.mat');
if nargin >= 1 && quick && exist(resf,'file')
    S = load(resf);  sol = S.sol;  cfg = S.cfg;  x0 = S.x0;  opt = S.opt;
    fprintf('保存済み計画を読み込み (falcon9): tf=%.1fs 燃料%.2ft\n', sol.tf, sol.propellant/1e3);
    return
end

cfg = scpk.modelFalcon9();
%% 計画には推力上限マージン15%を課す (追従MPCが残り15%を外乱補正に使える).
%% cfg.Tmax1 は制約箱にのみ効き力学には効かないので, 計画用コピーだけ下げる.
cfgPlan = cfg;
cfgPlan.Tmax1 = 0.85*cfg.Tmax1;  cfgPlan.Tmax = 0.85*cfg.Tmax;
qUp = [1;0;0;0];                            % テールファースト (機体x=上)
x0 = [2200; 0; -40; -240; 0; 10; qUp; 0;0;0; cfg.m0];
xT = [cfg.hmin; 0;0; 0;0;0; 0;0;0; 0;0;0];

phase = [1*ones(1,10), 2*ones(1,8), 3*ones(1,10), 4*ones(1,12)];  N = numel(phase);
eng   = [0*ones(1,10), 3*ones(1,8), 1*ones(1,10), 1*ones(1,12)];

%% 傾斜スケジュール: 全区間ほぼ直立 (フリップなし)
tiltN = deg2rad(15)*ones(1,N+1);
i3 = find(phase==3);  tiltN(i3(1):end) = deg2rad(10);
i4 = find(phase==4);  tiltN(i4(1):N+1) = deg2rad(6);

opt = scpk.planOptions6();
opt.phase = phase;  opt.engSched = eng;
opt.qBelly = qUp;  opt.bellyHold = 2;       % コースト中は直立を保持
opt.softGlide = true;  opt.tiltMaxNode = tiltN;
opt.monoDescent = true;  opt.drBox = [-160 10];  opt.crMax = 30;
opt.wMaxFlip = deg2rad(10);  opt.wMaxTight = deg2rad(5);
opt.sigMin = [1 3 4 3];  opt.sigMax = [4 8 14 9];
opt.lamTerm = 1e6;  opt.lamGlide = 2e5;  opt.phaseTight = 4;
opt.tiltMax = deg2rad(6);  opt.glideSlope = deg2rad(20);
opt.trShrinkRate = 0.93;  opt.trXmin = 3;  opt.trUmin = 2;  opt.trSigMin = 0.3;
opt.maxIter = 25;  opt.qp.maxIter = 6000;  opt.tolStep = 1e-3;
opt.wFuel = 15;  opt.useCpp = true;  opt.verbose = true;

%% pass 1: コールド
fprintf('=== falcon9 pass1: cold ===\n');
[sol,~] = scpk.plan6ft(x0, xT, [2 5 8 5], cfgPlan, opt);
%% pass 2: 終端を締める
fprintf('=== falcon9 pass2: tighten ===\n');
opt.lamTerm = 1e7;  opt.maxIter = 14;  opt.tolStep = 8e-4;  opt.verbose = false;
[sol,~] = scpk.plan6ft(x0, xT, sol.sigma, cfgPlan, opt, sol);
%% pass 3: 遅い点火の盆地へ誘導 (ホバースラムは早焚きの局所解に落ちやすい.
%% 「速度を高空で殺して停滞」する解が出たら, コースト下限で点火を遅らせる)
fprintf('=== falcon9 pass3: late-ignition ===\n');
sol.sigma = [7.5 4 4 1.8];
opt.sigMin = [6.5 1.5 2 1.2];  opt.sigMax = [9 5.5 9 5];
opt.lamTerm = 5e7;  opt.maxIter = 16;  opt.tolStep = 6e-4;
[sol,~] = scpk.plan6ft(x0, xT, sol.sigma, cfgPlan, opt, sol);
%% pass 4: 最終
opt.lamTerm = 1e8;  opt.maxIter = 14;  opt.tolStep = 5e-4;
[sol,~] = scpk.plan6ft(x0, xT, sol.sigma, cfgPlan, opt, sol);

rE = sol.r(:,end);  rd = quat2dcm(sol.q(:,end).').'*sol.v(:,end);
fprintf('終端: 高度%.1fm(目標%.0f) 水平%.1fm |v|%.2f 鉛直%+.2f 傾斜%.1fdeg 燃料%.2ft tf=%.1fs nu=%.1e\n', ...
    rE(1), cfg.hmin*cfg.sc.L, hypot(rE(2),rE(3)), norm(rd), rd(1), ...
    acosd(max(-1,1-2*(sol.q(3,end)^2+sol.q(4,end)^2))), sol.propellant/1e3, sol.tf, sol.virtCtrl);
save(resf, 'sol','cfg','x0','opt');
fprintf('保存: %s\n', resf);
end
