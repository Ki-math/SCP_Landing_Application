/* gnc_attitude.h — 姿勢内ループ + アクチュエータ動特性 (制御方式2, 手書き純C).
 *
 * MATLAB実装 (runClosedLoopReplan.m の方式2ブロック) の移植:
 *   - 姿勢PD則 (帯域 wnAtt / 減衰比 ztAtt のパラメータ化. Kp=wn^2, Kd=2*zt*wn)
 *   - MPC横推力のフィードフォワード + PD補正からジンバル角コマンドを生成
 *   - アクチュエータ: TVC 2次系 (wnGim/ztGim), スロットル/舵面 1次遅れ,
 *     オプションのスルーレート飽和 (前進オイラー, 刻み dtP)
 */
#ifndef GNC_ATTITUDE_H
#define GNC_ATTITUDE_H

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
    /* 内ループゲイン */
    double wnAtt;    /* 姿勢帯域 [rad/s] */
    double ztAtt;    /* 減衰比 */
    /* アクチュエータ動特性 */
    double tauThr;   /* スロットル1次遅れ [s] */
    double wnGim;    /* TVC 2次系 固有角周波数 [rad/s] (= 2*pi*fGim) */
    double ztGim;    /* TVC 減衰比 */
    double tauFlap;  /* 舵面1次遅れ [s] */
    int    actRateLim;   /* 1=スルーレート飽和有効 */
    double tvcRate;  /* ジンバル角速度上限 [rad/s] */
    double flapRate; /* 舵面角速度上限 [rad/s] */
    /* 機体定数 (物理単位) */
    double Lrt;      /* 推力作用点の腕長 |rT|·L [m] */
    double Jyy, Jzz; /* 慣性 [kg m^2] */
    double Fs;       /* 力スケール [N] */
    double tvcMax;   /* ジンバル最大角 [rad] */
    double scT;      /* 時間スケール (無次元角速度 -> rad/s の換算) */
} gnc_inner_cfg_t;

typedef struct {
    double Tm;       /* スロットル状態 (推力大きさ [N]) */
    double d[2];     /* ジンバル角 [rad] */
    double dd[2];    /* ジンバル角速度 [rad/s] */
    double f[4];     /* 舵角 [rad] */
} gnc_inner_state_t;

void gnc_inner_init(gnc_inner_state_t *s);

/* 1ステップ (dtP) 進めて適用制御 u[7] (無次元) を返す.
 * qCmd: 姿勢コマンド (trackStepEmb の出力, 正規化済み)
 * TcN : 推力大きさコマンド [N] (速度FB込み |[T1a; uMPC2,3]|*Fs)
 * uMPC: MPCの生の制御 (無次元 7. 横推力FFと舵角指令に使用)
 * x   : 現在状態 (無次元 14) */
void gnc_inner_step(const gnc_inner_cfg_t *c, gnc_inner_state_t *s,
                    const double qCmd[4], double TcN, const double uMPC[7],
                    const double x[14], double dtP, double u[7]);

#ifdef __cplusplus
}
#endif
#endif /* GNC_ATTITUDE_H */
