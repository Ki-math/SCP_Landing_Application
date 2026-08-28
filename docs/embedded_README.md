# SCP着陸誘導 組み込み用ソースパッケージ

MATLAB・MEX・BLAS/LAPACK に一切依存しない純 C/C++ ソースのみのパッケージです。
そのままターゲット環境へコピーし、C コンパイラでビルドするだけで動きます
(必要なのは libc / libm のみ)。

**部品として個別に使うことも、全部を組み合わせて誘導制御 (GNC) を構築する
こともできます**。部品の対応関係:

| 部品 | 役割 | 単体利用 |
|---|---|---|
| gnc/ `scpk_planIterEmb` | 計画SCP 1反復 (フル計画/オンライン再計画) | 可 (examples/main_planner_example.c) |
| gnc/ `scpk_trackStepEmb` | 追従MPC 1周期 (LTV追従QP) | 可 (examples/main_tracker_example.c) |
| gnc/ `dyn` | 6自由度力学 (ISA大気・風テーブル込み) | 可 (プラントシミュレーション等) |
| guidance/ | 参照サンプリング・点火ディスパッチ・鉛直速度FB | 可 (手書き純C, 依存なし) |
| solver/ `pipg_solve_csc` | PIPG QPソルバ単体 (ヘッダオンリー) | 可 (examples/main_solver_example.cpp) |
| 全部 | 誘導制御ループ | examples/main_gnc_example.c |

## 構成

```
gnc/        GNCコアのフルC実装 (MATLAB Coder 生成, BLASフリー)
            エントリポイント (独立に呼び出し可能):
              scpk_planIterEmb  (scpk_planIterEmb.h)  計画SCP 1反復
              scpk_trackStepEmb (scpk_trackStepEmb.h) 追従MPC 1周期
              dyn               (dynamics6.h)         6自由度力学
            型定義は gncCore_lib_types.h で共有
guidance/   誘導・制御ロジック部品 (手書き純C):
              gnc_guidance.h    参照サンプリング / 点火ディスパッチ
                                (高度→参照時刻) / 鉛直速度FB
              gnc_attitude.h    姿勢内ループ (制御方式2: PD則 wnAtt/ztAtt)
                                + アクチュエータ動特性 (TVC2次系,
                                スロットル・舵面1次遅れ, スルーレート飽和)
solver/     手書きC++ PIPG QPソルバ単体 (pipg_core.hpp, ヘッダオンリー)
            エントリポイント: pipg_solve_csc (Cリンケージ)
examples/   実データ入りサンプル main
            main_planner_example.c  計画1反復デモ (Starship着陸問題の実データ)
            main_tracker_example.c  追従MPC 1周期デモ
            main_gnc_example.c      GNC統合閉ループ (完全構成: gnc_loop.h)
            gnc_loop.h              閉ループ本体. ホストMATLABの閉ループ
                                    (runClosedLoopReplan) と同一構成:
                                    点火ディスパッチ→追従MPC→速度FB→
                                    着陸コミット→内ループ+アクチュエータ
                                    (方式2時)→カットオフ→プラントRK4.
                                    制御方式・誘導設定は ex_ctl* 定数
                                    (機体テンプレート由来) に自動追随
            main_solver_example.cpp ソルバ単体デモ (解析解つき小QP)
            plan_example_data.h     実データ (MATLAB側 exportPlanExample.m が生成)
README.md   本ファイル
```

## ビルドと実行

パッケージ直下で:

```sh
# 1) 計画単体デモ (C)
gcc -O2 -Ignc -Iexamples examples/main_planner_example.c gnc/*.c -o planner_demo -lm
./planner_demo
#   cold : status=1 iters=~1100  ~120 ms
#   warm : status=1 iters=25     ~10 ms     <- 100ms周期の再計画はこの形

# 2) 追従MPC単体デモ (C)
gcc -O2 -Ignc -Iguidance -Iexamples examples/main_tracker_example.c \
    gnc/*.c guidance/*.c -o tracker_demo -lm
./tracker_demo
#   固定300反復 (決定的) ~9-12 ms / 周期

# 3) GNC統合閉ループデモ (C. 着陸まで通し実行)
gcc -O2 -Ignc -Iguidance -Iexamples examples/main_gnc_example.c \
    gnc/*.c guidance/*.c -o gnc_demo -lm
./gnc_demo
#   接地: 水平 ~7 m | 鉛直 ~-2.5 m/s | 傾斜 ~0.8 deg (推力効率0.97の外乱つき)

# 4) ソルバ単体デモ (C++)
g++ -O2 -Isolver examples/main_solver_example.cpp -o solver_demo
./solver_demo
```

MSVC の場合: `cl /O2 /Ignc /Iguidance /Iexamples examples\main_gnc_example.c gnc\*.c guidance\*.c`

## エントリポイント仕様

### 1. 計画 SCP 1反復 — `scpk_planIterEmb`

SCP (逐次凸化) の 1 反復 = 「参照軌道まわりの線形化 + QP行列組み立て +
Ruiz前処理 + PIPG求解 + 解の展開」を 1 回実行します。周期実行で呼び、
前回の解を次の初期推定 (`xl,ul,gl,sigl`) と内部ウォームスタート (`zWarm`)
に渡すのが実運用の形です (examples/main_planner_example.c 参照)。

```c
void scpk_planIterEmb(
  const double x0nd[14],   /* 現在状態 (無次元) [r(3);vB(3);q(4);w(3);m^] */
  const double xT[12],     /* 終端目標 (無次元12, 質量除く) */
  const double xl_data[],  const int xl_size[2],   /* 参照状態 14×(N+1) */
  const double ul_data[],  const int ul_size[2],   /* 参照制御 7×N */
  const double gl_data[],  const int gl_size[2],   /* 参照推力ノルム 1×N */
  const double sigl_data[],const int sigl_size[2], /* フェーズ時間σ 1×P */
  const double phase_data[],const int phase_size[2], /* ノード→フェーズ番号 1×N */
  const double eng_data[], const int eng_size[2],  /* ノード→エンジン数 1×N */
  const double dtv_data[], const int dtv_size[2],  /* ノード正規化時間幅 1×N */
  const double tiltN_data[],const int tiltN_size[2],/* 傾斜上限[rad] 1×(N+1) */
  const struct0_T *cfg,    /* 機体定数 (fill_cfg 参照) */
  const struct3_T *pp,     /* 計画パラメータ: スケーリング/重み/制約 */
  const struct4_T *qp,     /* QPソルバ設定 */
  const emxArray_real_T *zWarm,  /* 前回 zOut. 初回は長さ0 */
  double xs_data[], int xs_size[2],   /* 出力: 状態軌道 14×(N+1) */
  double us_data[], int us_size[2],   /* 出力: 制御軌道 7×N */
  double gs_data[], int gs_size[2],   /* 出力: 推力ノルム 1×N */
  double ss_data[], int ss_size[2],   /* 出力: σ 1×P */
  int *st,                 /* 1=converged 0=maxIter 2/3=infeasible 4=numeric */
  int *iters, double *nu,  /* QP反復数 / 仮想制御ノルム (0が物理的に有効) */
  double *step,            /* 反復ステップ量 (収束判定に使用) */
  emxArray_real_T *zOut);  /* 次回 zWarm に渡す内部状態 */
```

- 出力バッファは呼び出し側が最大サイズ (`xs[14*201]` 等) で確保します。
- `emxArray_real_T` は `gncCore_lib_emxAPI.h` の
  `emxCreate_real_T` / `emxDestroyArray_real_T` で生成・破棄します。
- 呼び出し前に `gncCore_lib_initialize()`、終了時に
  `gncCore_lib_terminate()` を 1 度だけ呼びます (全エントリ共通)。
- SCP 収束ループ: `step` が十分小さく `nu≈0` になるまで反復
  (ホスト側 MATLAB の scpk.plan6ft と同じ判定)。

### 2. 追従MPC 1周期 — `scpk_trackStepEmb`

参照軌道まわりの LTV 追従QP (偏差座標・許容誤差スケール) を 1 回解き、
今周期に適用する制御を返します。固定反復モード (既定 300) で実行時間は
決定的です。参照窓 `xr/ur/engk` は guidance/ の `gnc_ref_window` で作れます。

```c
void scpk_trackStepEmb(
  const double xcPhys[14],   /* 現在状態 (物理単位: m, m/s, -, rad/s, kg) */
  const double xr_data[], const int xr_size[2],   /* 参照状態 14×(H+1), 無次元 */
  const double ur_data[], const int ur_size[2],   /* 参照制御 7×H */
  const double engk_data[], const int engk_size[2], /* 点火基数 1×H */
  const struct0_T *cfg,      /* 機体定数 (計画と同じ) */
  const struct5_T *tp,       /* 追従パラメータ (fill_tp 参照) */
  const double zWarm_data[], const int zWarm_size[1], /* 前周期の解 (21H) */
  double u0[7],              /* 出力: 適用制御 (無次元 [T_B(3); flap(4)]) */
  double zOut_data[], int zOut_size[1],  /* 出力: 次周期ウォームスタート */
  double qCmd[4],            /* 出力: 姿勢コマンド (内ループ構成用) */
  int *st, int *iters);      /* QP状態 / 反復数 */
```

### 3. 誘導ロジック部品 — guidance/gnc_guidance.h

ヘッダのコメントに各関数の仕様を記載。代表的な使い方
(ホバースラム機の点火ディスパッチ + 速度FB):

```c
gnc_alt_tab_t tab;  gnc_alt_table(&ref, scL, &tab);
double tRef = gnc_dispatch_time(&tab, alt_m);       /* 高度で参照を引く */
gnc_ref_window(&ref, tRef, dtMpc, H, xr, ur, engk); /* MPC窓 */
...
T1 = gnc_velfb_step(&vfb, vRef - v, mass, u0[0], engN,
                    Tmin1, Tmax1, Fs, dtP);          /* 鉛直速度トリム */
```

### 4. QPソルバ単体 — `pipg_solve_csc`

箱制約つき凸QP `min 0.5 z'Pz + q'z  s.t. Cz{=,<=}d, lb<=z<=ub`
(P は対角、C は CSC 疎行列、先頭 `neq` 行が等式) を PIPG で解きます。

```c
int pipg_solve_csc(                       /* 返り値 = status (上と同じ) */
  const double *Pd, const double *q,      /* 対角P, 線形項 (長さn) */
  int32_t n, int32_t m, int32_t neq,
  const int32_t *jc, const int32_t *ir, const double *pr,  /* C の CSC (0始まり) */
  const double *d, const double *lb, const double *ub,
  const pipg::Opt *opt,                   /* 設定 (main_solver_example.cpp の既定値) */
  double *z, double *w,                   /* 入出力: ウォームスタート/解 (n, m) */
  int *iters, double *resPri, double *resDua);
```

- MATLAB 参照実装 (scpk.solveQP) とビット一致を検証済み。
- 非収束時も status で必ず原因を名乗ります (infeasibility 証明書つき)。

## 例データの機体

生成コード (gnc/) は**機体非依存**です — 機体は実行時引数 `cfg` で渡す
プラグイン設計で, Starship でも Falcon9 でも独自機体でも同じコードが動きます。
`examples/plan_example_data.h` の実データだけが特定機体の計画解で、
`scpCodegenZip(regen, 'falcon9')` (GUIでは選択中の機体に自動追随) で
切り替えられます。`verifyEmbedded` もそのデータの機体で検証します。

## 引数データの作り方 (ホストMATLAB側)

`examples/plan_example_data.h` は雛形です。自機体・自シナリオのデータは
ホスト側プロジェクトで:

```matlab
prob = scpProblem('starship');        % または独自機体
sol  = scpPlan(prob);                 % 収束解 (初期推定として最良)
util/exportPlanExample.m              % を参考に同形式のヘッダを出力
```

構造体 `cfg`/`pp`/`qp`/`tp` の中身は `scpk.model6` / `scpk.planParams` /
`scpk.trackParams` が生成する値そのもので、フィールド順は
`gnc/gncCore_lib_types.h` の typedef と一致します
(fill_cfg / fill_pp / fill_qp / fill_tp が全フィールドを代入)。

## 性能実測 (参考, x86-64 -O2)

| 処理 | 時間 |
|---|---|
| 計画1反復 cold (QP ~1100反復) | ~120 ms |
| 計画1反復 warm (QP 25反復) | ~10 ms |
| 追従MPC 1周期 (固定300反復, 線形化込み) | ~9-12 ms |
| GNC統合閉ループの着陸例 (Starship, thrEff 0.97) | 水平 ~7 m / -2.5 m/s / 0.8° |

## 等価性検証

`examples/main_verify.c` は計画1反復・追従MPC 1周期・GNC閉ループ (着陸までの
シミュレーション) の結果を全桁でファイル出力する検証用プログラムです。ホスト
MATLAB側で `verifyEmbedded` を実行すると、本パッケージを展開 → gcc でビルド →
実行し、**MATLAB参照実装との数値一致**を自動判定・プロット表示します。
閉ループはホストの閉ループ本体 (runClosedLoopReplan) と直接比較され、制御方式も
機体テンプレートに従います (実測: 状態軌道 ~3e-11, 閉ループ軌跡
方式1(falcon9) 2.4e-8 m / 方式2(starship, 内ループ+アクチュエータ) 2.5e-9 m,
QP反復数は完全一致)。

```
>> verifyEmbedded
=== 総合判定: PASS (数値一致) ===
```

## 注意

- `gnc/` は生成コードです。修正はホスト側 (scpk.planIterEmb /
  scpk.trackStepEmb ほか) で行い再生成してください (`scpCodegenZip(true)`)。
- `guidance/` は手書きCなので直接カスタマイズできます。
- 数式・アルゴリズムの詳細はプロジェクトの docs/SCP_formulation.md を参照。
