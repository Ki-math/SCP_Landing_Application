/*
 * File: scpk_trackStepEmb.h
 *
 * MATLAB Coder version            : 24.2
 * C/C++ source code generated on  : 2026/08/28 19:09:09
 */

#ifndef SCPK_TRACKSTEPEMB_H
#define SCPK_TRACKSTEPEMB_H

/* Include Files */
#include "gncCore_lib_types.h"
#include "rtwtypes.h"
#include <stddef.h>
#include <stdlib.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Function Declarations */
extern void scpk_trackStepEmb(const double xcPhys[14], const double xr_data[],
                              const int xr_size[2], const double ur_data[],
                              const int ur_size[2], const double engk_data[],
                              const int engk_size[2], const struct0_T *cfg,
                              const struct5_T *tp, const double zWarm_data[],
                              const int zWarm_size[1], double u0[7],
                              double zOut_data[], int zOut_size[1],
                              double qCmd[4], int *st, int *iters);

#ifdef __cplusplus
}
#endif

#endif
/*
 * File trailer for scpk_trackStepEmb.h
 *
 * [EOF]
 */
