/* main_gnc_example.c — 生成コード部品を組み合わせた誘導制御ループの統合例.
 *
 * 完全構成 (すべて純C, MATLAB非依存. gnc_loop.h に実装):
 *   点火ディスパッチ (高度同期の機体) -> 追従MPC scpk_trackStepEmb (dtCtrl周期)
 *   -> 鉛直速度FB / 着陸コミット / 姿勢内ループ+アクチュエータ (方式2の機体)
 *   / エンジンカットオフ -> 推力効率誤差つきプラント (dyn() の RK4, dtPlant)
 * 制御方式・誘導設定は plan_example_data.h の ex_ctl* 定数
 * (機体テンプレート scpProblem 由来. GUI/exportPlanExample で機体を切替).
 *
 * オンライン再計画を足す場合は, scpk_planIterEmb を誤差トリガで呼び,
 * 返った解で参照テーブルを差し替えればよい (main_planner_example.c 参照).
 *
 * ビルド (パッケージ直下で):
 *   gcc -O2 -Ignc -Iguidance -Iexamples examples/main_gnc_example.c \
 *       gnc/*.c guidance/*.c -o gnc_demo -lm
 * 実行:
 *   ./gnc_demo
 */
#include <stdio.h>
#include <math.h>
#include <time.h>
#include "scpk_trackStepEmb.h"
#include "gncCore_lib_initialize.h"
#include "gncCore_lib_terminate.h"
#include "dynamics6.h"          /* dyn(): 6自由度力学 (生成コード) */
#include "plan_example_data.h"
#include "gnc_guidance.h"
#include "gnc_attitude.h"
#include "gnc_loop.h"

#define THR_EFF 0.97            /* 外乱: 推力効率 (実推力 = 指令 x 0.97) */

int main(void)
{
    static struct0_T cfg;
    static struct5_T tp;
    gnc_result_t r;
    double tilt, horiz, vI1;

    gncCore_lib_initialize();
    fill_cfg(&cfg);  fill_tp(&tp);

    printf("GNC統合ループ開始 (方式%d, %s同期, 速度FB=%.1f, MPC %.0f ms / プラント %.0f ms, 推力効率 %.2f)\n",
           ex_ctlInner ? 2 : 1, ex_refSyncAlt ? "高度" : "時刻", ex_velFB,
           ex_dtCtrl*1000.0, ex_dtPlant*1000.0, THR_EFF);

    r = gnc_run(&cfg, &tp, THR_EFF, NULL);

    horiz = ex_scL*sqrt(r.x[1]*r.x[1] + r.x[2]*r.x[2]);
    tilt = acos(fmax(-1.0, fmin(1.0, 1.0-2.0*(r.x[8]*r.x[8]+r.x[9]*r.x[9]))))*180.0/M_PI;
    vI1 = gnc_vI1(r.x)*ex_scV;
    printf("接地 t=%.1fs: 水平 %.2f m | 鉛直速度 %+.2f m/s | 傾斜 %.2f deg\n",
           r.t, horiz, vI1, tilt);
    printf("追従MPC %d回: 平均 %.1f ms / 最大 %.1f ms\n", r.nMpc, r.msMean, r.msMax);

    gncCore_lib_terminate();
    return (horiz < 30.0 && fabs(vI1) < 15.0) ? 0 : 1;
}
