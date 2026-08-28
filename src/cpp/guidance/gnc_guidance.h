/* gnc_guidance.h — 誘導ロジック部品 (手書き移植, 依存なしの純C).
 *
 * MATLAB実装 (runClosedLoopReplan.m) から移植した3部品:
 *   1. 参照サンプリング  : 計画解から追従MPCのホライズン窓を切り出す
 *   2. 点火ディスパッチ  : 高度→参照時刻の逆引き (ホバースラムの点火タイミング
 *                          分散を吸収する. refSync='alt' 相当)
 *   3. 鉛直速度FB        : 参照 v(h) への推力トリム (ホバー不能機のブレーキ補償)
 *
 * 各部品は独立に使用可能. 全体を組み合わせた誘導制御ループの例は
 * examples/main_gnc_example.c を参照.
 */
#ifndef GNC_GUIDANCE_H
#define GNC_GUIDANCE_H

#ifdef __cplusplus
extern "C" {
#endif

/* ---- 参照軌道 (計画解の高密度化データ. 列優先 14 x n / 7 x nu) ---- */
typedef struct {
    const double *t;    /* 時刻 [s] (n) */
    const double *x;    /* 状態 (無次元, 14 x n, 列優先) */
    const double *u;    /* 制御 (無次元, 7 x nu, 列優先) */
    const double *eng;  /* 点火基数 (nu) */
    int n;              /* 状態ノード数 */
    int nu;             /* 制御ノード数 */
} gnc_ref_t;

/* 状態の線形補間 (四元数は正規化) */
void gnc_ref_state(const gnc_ref_t *ref, double tq, double x14[14]);
/* 制御のZOH (直前ノード値) */
void gnc_ref_ctrl(const gnc_ref_t *ref, double tq, double u7[7]);
/* 点火基数のZOH */
double gnc_ref_eng(const gnc_ref_t *ref, double tq);
/* 追従MPCのホライズン窓: xr(14 x H+1), ur(7 x H), engk(H) を列優先で埋める */
void gnc_ref_window(const gnc_ref_t *ref, double t0, double dt, int H,
                    double *xr, double *ur, double *engk);

/* ---- 点火ディスパッチ (高度→参照時刻の逆引き表) ---- */
#define GNC_ALTTAB_MAX 8192
typedef struct {
    double h[GNC_ALTTAB_MAX];   /* 高度 [m] (昇順) */
    double t[GNC_ALTTAB_MAX];   /* 対応する参照時刻 [s] */
    int n;
} gnc_alt_tab_t;

/* 参照の高度履歴から単調な逆引き表を作る (scL: 長さスケール [m]) */
void gnc_alt_table(const gnc_ref_t *ref, double scL, gnc_alt_tab_t *tab);
/* 現在高度 [m] から参照時刻 [s] を引く (範囲外はクランプ) */
double gnc_dispatch_time(const gnc_alt_tab_t *tab, double alt_m);

/* ---- 鉛直速度フィードバック (10ms層の推力トリム) ---- */
typedef struct {
    double kVel;    /* 比例ゲイン [1/s] */
    double kInt;    /* 積分ゲイン [1/s^2] (0で無効) */
    double tauLpf;  /* 速度誤差LPF時定数 [s] (推力ジッタ→傾斜結合を切る) */
    double dvF;     /* 内部状態: LPF後の速度誤差 [m/s] */
    double Tint;    /* 内部状態: 積分トリム (無次元推力) */
} gnc_velfb_t;

void gnc_velfb_init(gnc_velfb_t *s, double kVel, double kInt);
/* dvx_ms: 機体x速度誤差 (参照-実) [m/s], mass_kg: 現在質量,
 * T1_nd: MPCの推力x (無次元), engN: 点火基数, Tmin1/Tmax1: 1基あたり推力範囲
 * (無次元), Fs: 力スケール [N], dtP: 刻み [s]. 戻り値: トリム後の推力x (無次元) */
double gnc_velfb_step(gnc_velfb_t *s, double dvx_ms, double mass_kg,
                      double T1_nd, double engN, double Tmin1, double Tmax1,
                      double Fs, double dtP);

#ifdef __cplusplus
}
#endif
#endif /* GNC_GUIDANCE_H */
