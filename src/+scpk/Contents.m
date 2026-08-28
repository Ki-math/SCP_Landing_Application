% SCPK  逐次凸計画による着陸誘導ツールキット (外部ライブラリ非依存)
%
% 設計方針
%   ・QP は自作の PIPG のみで解く. 行列ベクトル積と射影だけで構成され,
%     固定反復にすれば決定的な実行時間になり, コード生成にそのまま乗る.
%   ・変数は「許容誤差」で無次元化する. 重み Q = 1/tol^2 で表現すると
%     Hessian に何桁もの開きが生じ, 一次法が収束しない.
%   ・単純な上下限は箱制約に分離し, 一般不等式に残さない.
%   ・全変数に一様な正則化を入れて平坦方向を消す. これが無いと前処理の
%     列スケーリングが平坦方向を増幅して逆効果になる.
%
% ソルバ
%   solveQP        - 箱制約付き凸QP の PIPG 求解
%   qpOptions      - solveQP の設定
%   precondition   - Ruiz 平衡化による対角前処理
%   discretize     - ZOH 離散化 (expm 非依存の打ち切り級数)
%   scaling        - 許容誤差ベースのスケーリング
%
% モデル
%   model          - 機体/モデル定数 (無次元化済み)
%   dynamics       - 平面6-DoF ダイナミクスと解析ヤコビアン
%   verify         - 解を真の非線形ダイナミクスで再積分して検証
%
% 軌道計画
%   plan             - 接地までの軌道を SCP で解く
%   planContinuation - 離散化を段階的に細かくしながら計画 (推奨)
%   buildPlan        - 計画の部分問題を QP として組む
%   planOptions      - 計画の設定
%
% 追従と再計画
%   trackStep      - 短水平 MPC を1回解き姿勢/推力指令を返す
%   buildTrack     - 追従MPC の QP を組む
%   trackOptions   - 追従MPC の設定
%   replan         - 現在状態から接地までを引き直す
%   replanOptions  - 再計画の設定
%
% 検証
%   runClosedLoop  - 計画 + 周期再計画 + 追従MPC の閉ループシミュレーション
%
% 使用例
%   cfg  = scpk.model();
%   popt = scpk.planOptions();  popt.engSchedFrac = 0.72;
%   x0   = [300; -167; -62.7; 0; deg2rad(90); 0; cfg.m0];
%   xT   = [cfg.hmin*cfg.sc.L; 0; -1; 0; 0; 0];
%   plan = scpk.planContinuation(x0, xT, 7.0, cfg, popt, [10 15 25]);
%
%   topt = scpk.trackOptions();
%   ropt = scpk.replanOptions();
%   out  = scpk.runClosedLoop(plan, cfg, topt, x0, 0.2, ropt);
