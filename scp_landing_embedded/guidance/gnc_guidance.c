/* gnc_guidance.c — 誘導ロジック部品の実装 (gnc_guidance.h 参照). */
#include "gnc_guidance.h"
#include <math.h>

/* ---- 内部: 昇順配列 a[n] で aq を挟む区間の左インデックス (0..n-2) ---- */
static int bracket(const double *a, int n, double aq)
{
    int lo = 0, hi = n - 1, mid;
    if (aq <= a[0]) return 0;
    if (aq >= a[n-1]) return n - 2;
    while (hi - lo > 1) {
        mid = (lo + hi) / 2;
        if (a[mid] <= aq) lo = mid; else hi = mid;
    }
    return lo;
}

void gnc_ref_state(const gnc_ref_t *ref, double tq, double x14[14])
{
    int k, i;
    double s, nq;
    if (tq < ref->t[0]) tq = ref->t[0];
    if (tq > ref->t[ref->n-1]) tq = ref->t[ref->n-1];
    k = bracket(ref->t, ref->n, tq);
    s = (tq - ref->t[k]) / (ref->t[k+1] - ref->t[k] + 1e-300);
    for (i = 0; i < 14; i++)
        x14[i] = ref->x[14*k+i] + s * (ref->x[14*(k+1)+i] - ref->x[14*k+i]);
    nq = sqrt(x14[6]*x14[6] + x14[7]*x14[7] + x14[8]*x14[8] + x14[9]*x14[9]);
    if (nq > 1e-12) { for (i = 6; i < 10; i++) x14[i] /= nq; }
}

void gnc_ref_ctrl(const gnc_ref_t *ref, double tq, double u7[7])
{
    int k, i;
    if (tq < ref->t[0]) tq = ref->t[0];
    if (tq > ref->t[ref->nu-1]) tq = ref->t[ref->nu-1];
    k = bracket(ref->t, ref->nu, tq);          /* ZOH: 左ノード値 */
    for (i = 0; i < 7; i++) u7[i] = ref->u[7*k+i];
}

double gnc_ref_eng(const gnc_ref_t *ref, double tq)
{
    int k;
    if (tq < ref->t[0]) tq = ref->t[0];
    if (tq > ref->t[ref->nu-1]) tq = ref->t[ref->nu-1];
    k = bracket(ref->t, ref->nu, tq);
    return ref->eng[k];
}

void gnc_ref_window(const gnc_ref_t *ref, double t0, double dt, int H,
                    double *xr, double *ur, double *engk)
{
    int k;
    double tk;
    for (k = 0; k <= H; k++) {
        tk = t0 + k * dt;
        if (tk > ref->t[ref->n-1]) tk = ref->t[ref->n-1];
        gnc_ref_state(ref, tk, &xr[14*k]);
    }
    for (k = 0; k < H; k++) {
        tk = t0 + k * dt;
        if (tk > ref->t[ref->n-1]) tk = ref->t[ref->n-1];
        gnc_ref_ctrl(ref, tk, &ur[7*k]);
        engk[k] = gnc_ref_eng(ref, tk);
    }
}

void gnc_alt_table(const gnc_ref_t *ref, double scL, gnc_alt_tab_t *tab)
{
    /* 高度履歴を単調非増加化 (累積min) + 微小オフセットで厳密単調化し,
     * 反転して昇順の逆引き表にする (MATLAB altTable と同一) */
    int i, n = ref->n;
    double a, amin = 1e300;
    if (n > GNC_ALTTAB_MAX) n = GNC_ALTTAB_MAX;
    for (i = 0; i < n; i++) {
        a = ref->x[14*i+0] * scL;
        if (a < amin) amin = a;
        tab->h[n-1-i] = amin - (double)i * 1e-9;
        tab->t[n-1-i] = ref->t[i];
    }
    tab->n = n;
}

double gnc_dispatch_time(const gnc_alt_tab_t *tab, double alt_m)
{
    int k;
    double s;
    if (alt_m <= tab->h[0]) return tab->t[0];
    if (alt_m >= tab->h[tab->n-1]) return tab->t[tab->n-1];
    k = bracket(tab->h, tab->n, alt_m);
    s = (alt_m - tab->h[k]) / (tab->h[k+1] - tab->h[k] + 1e-300);
    return tab->t[k] + s * (tab->t[k+1] - tab->t[k]);
}

void gnc_velfb_init(gnc_velfb_t *s, double kVel, double kInt)
{
    s->kVel = kVel;  s->kInt = kInt;  s->tauLpf = 0.3;
    s->dvF = 0.0;    s->Tint = 0.0;
}

double gnc_velfb_step(gnc_velfb_t *s, double dvx_ms, double mass_kg,
                      double T1_nd, double engN, double Tmin1, double Tmax1,
                      double Fs, double dtP)
{
    double T1a, lim;
    if (s->kVel <= 0.0 || engN <= 0.0) return T1_nd;
    s->dvF += dtP / s->tauLpf * (dvx_ms - s->dvF);
    s->Tint += s->kInt * mass_kg * s->dvF / Fs * dtP;
    lim = 0.15 * engN * Tmax1;
    if (s->Tint >  lim) s->Tint =  lim;
    if (s->Tint < -lim) s->Tint = -lim;
    T1a = T1_nd + s->kVel * mass_kg * s->dvF / Fs + s->Tint;
    if (T1a < engN * Tmin1) T1a = engN * Tmin1;
    if (T1a > engN * Tmax1) T1a = engN * Tmax1;
    return T1a;
}
