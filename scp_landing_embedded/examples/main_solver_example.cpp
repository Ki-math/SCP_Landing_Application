/* main_solver_example.cpp — pipg_core.hpp の呼び出し例 (自己完結・実行可能).
 *
 * ビルド:  g++ -O2 -I. main_solver_example.cpp -o solver_demo
 * 実行  :  ./solver_demo
 *
 * 解く問題 (解析解と比較できる小さなQP):
 *   min 0.5*(z1^2+z2^2) + z1 - z2   s.t. z1 + z2 = 0,  -10 <= z <= 10
 *   解析解: z = [-1, +1], 目的値 = -1
 */
#include <stdio.h>
#include "pipg_core.hpp"

int main(void)
{
    /* --- 問題データ --- */
    const int32_t n = 2, m = 1, neq = 1;
    double Pd[2] = {1.0, 1.0};              /* P = diag(Pd) */
    double q[2]  = {1.0, -1.0};
    /* C = [1 1] (1x2, CSC形式: 列ごとに格納) */
    int32_t jc[3] = {0, 1, 2};              /* 列ポインタ (0始まり) */
    int32_t ir[2] = {0, 0};                 /* 行インデックス */
    double  pr[2] = {1.0, 1.0};             /* 値 */
    double d[1]  = {0.0};
    double lb[2] = {-10.0, -10.0};
    double ub[2] = { 10.0,  10.0};

    /* --- ソルバ設定 (MATLAB 側 scpk.qpOptions と同じ既定) --- */
    pipg::Opt opt;
    opt.maxIter = 4000;   opt.fixedIter = 0;
    opt.tolPri = 1e-6;    opt.tolDua = 1e-6;
    opt.omega = 1e2;      opt.rho = 1.7;
    opt.checkEvery = 25;  opt.powerIter = 30;
    opt.certAfter = 200;  opt.certTol = 1e-8;  opt.certEps = 1e-4;

    /* --- 求解 (z, w はウォームスタート入力兼 解の出力) --- */
    double z[2] = {0.0, 0.0};
    double w[1] = {0.0};
    int iters = 0;
    double rp = 0.0, rd = 0.0;
    int status = pipg_solve_csc(Pd, q, n, m, neq, jc, ir, pr, d, lb, ub,
                                &opt, z, w, &iters, &rp, &rd);

    const char *names[] = {"maxIter","converged","primalInfeasible",
                           "dualInfeasible","numericalFailure"};
    printf("status = %d (%s), iters = %d\n", status, names[status], iters);
    printf("z = [%f, %f]   (expected [-1, +1])\n", z[0], z[1]);
    printf("residual: primal %.3e, dual %.3e\n", rp, rd);
    return (status == 1) ? 0 : 1;
}
