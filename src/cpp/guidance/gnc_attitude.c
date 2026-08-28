/* gnc_attitude.c — 姿勢内ループ + アクチュエータ動特性の実装 (gnc_attitude.h 参照).
 * MATLAB実装 (runClosedLoopReplan.m 方式2ブロック) と演算順序まで同一. */
#include "gnc_attitude.h"
#include <math.h>

static double clampd(double v, double lo, double hi)
{
    if (v < lo) return lo;
    if (v > hi) return hi;
    return v;
}

void gnc_inner_init(gnc_inner_state_t *s)
{
    int i;
    s->Tm = 0.0;
    s->d[0] = s->d[1] = 0.0;
    s->dd[0] = s->dd[1] = 0.0;
    for (i = 0; i < 4; i++) s->f[i] = 0.0;
}

void gnc_inner_step(const gnc_inner_cfg_t *c, gnc_inner_state_t *s,
                    const double qCmd[4], double TcN, const double uMPC[7],
                    const double x[14], double dtP, double u[7])
{
    double qe0, qe1, qe2, qe3, sgn;
    double eAtt[3], wB[3], aDes[3], T2c, T3c, dCmd[2], df;
    const double q0 = x[6], q1 = x[7], q2 = x[8], q3 = x[9];
    int i;

    /* 姿勢誤差 qe = q^-1 (x) qCmd (機体系小角ベクトル) */
    qe0 = q0*qCmd[0] + q1*qCmd[1] + q2*qCmd[2] + q3*qCmd[3];
    qe1 = q0*qCmd[1] - q1*qCmd[0] - q2*qCmd[3] + q3*qCmd[2];
    qe2 = q0*qCmd[2] + q1*qCmd[3] - q2*qCmd[0] - q3*qCmd[1];
    qe3 = q0*qCmd[3] - q1*qCmd[2] + q2*qCmd[1] - q3*qCmd[0];
    sgn = (qe0 >= 0.0) ? 1.0 : -1.0;
    if (qe0 == 0.0) sgn = 0.0;                    /* MATLAB sign() と同一 */
    eAtt[0] = 2.0*sgn*qe1;  eAtt[1] = 2.0*sgn*qe2;  eAtt[2] = 2.0*sgn*qe3;
    for (i = 0; i < 3; i++) wB[i] = x[10+i]/c->scT;      /* 角速度 [rad/s] */
    for (i = 0; i < 3; i++)
        aDes[i] = c->wnAtt*c->wnAtt*eAtt[i] - 2.0*c->ztAtt*c->wnAtt*wB[i];
    /* 必要横推力: M2=+L*T3, M3=-L*T2 */
    T3c =  aDes[1]*c->Jyy/c->Lrt;
    T2c = -aDes[2]*c->Jzz/c->Lrt;
    /* ジンバル角コマンド = MPC横推力FF + PD補正 (小角) */
    {
        double den = (TcN > 1e3) ? TcN : 1e3;
        dCmd[0] = clampd((uMPC[1]*c->Fs + T2c)/den, -c->tvcMax, c->tvcMax);
        dCmd[1] = clampd((uMPC[2]*c->Fs + T3c)/den, -c->tvcMax, c->tvcMax);
    }
    /* アクチュエータ: TVC 2次系 + スロットル/舵面 1次遅れ (前進オイラー) */
    for (i = 0; i < 2; i++) {
        s->dd[i] += dtP*(c->wnGim*c->wnGim*(dCmd[i] - s->d[i]) - 2.0*c->ztGim*c->wnGim*s->dd[i]);
        if (c->actRateLim) s->dd[i] = clampd(s->dd[i], -c->tvcRate, c->tvcRate);
    }
    for (i = 0; i < 2; i++) s->d[i] += dtP*s->dd[i];
    s->Tm += dtP*(TcN - s->Tm)/c->tauThr;
    for (i = 0; i < 4; i++) {
        df = (uMPC[3+i] - s->f[i])/c->tauFlap;
        if (c->actRateLim) df = clampd(df, -c->flapRate, c->flapRate);
        s->f[i] += dtP*df;
    }
    u[0] = s->Tm/c->Fs;
    u[1] = s->Tm*s->d[0]/c->Fs;
    u[2] = s->Tm*s->d[1]/c->Fs;
    for (i = 0; i < 4; i++) u[3+i] = s->f[i];
    if (TcN < 1e3) { u[0] = 0.0; u[1] = 0.0; u[2] = 0.0; }   /* エンジン停止中 */
}
