/*
 * File: scpk_planIterEmb.h
 *
 * MATLAB Coder version            : 24.2
 * C/C++ source code generated on  : 2026/08/28 22:18:33
 */

#ifndef SCPK_PLANITEREMB_H
#define SCPK_PLANITEREMB_H

/* Include Files */
#include "gncCore_lib_types.h"
#include "rtwtypes.h"
#include <stddef.h>
#include <stdlib.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Function Declarations */
extern void scpk_planIterEmb(
    const double x0nd[14], const double xT[12], const double xl_data[],
    const int xl_size[2], const double ul_data[], const int ul_size[2],
    const double gl_data[], const int gl_size[2], const double sigl_data[],
    const int sigl_size[2], const double phase_data[], const int phase_size[2],
    const double eng_data[], const int eng_size[2], const double dtv_data[],
    const int dtv_size[2], const double tiltN_data[], const int tiltN_size[2],
    const struct0_T *cfg, const struct3_T *pp, const struct4_T *qp,
    const emxArray_real_T *zWarm, double xs_data[], int xs_size[2],
    double us_data[], int us_size[2], double gs_data[], int gs_size[2],
    double ss_data[], int ss_size[2], int *st, int *iters, double *nu,
    double *step, emxArray_real_T *zOut);

#ifdef __cplusplus
}
#endif

#endif
/*
 * File trailer for scpk_planIterEmb.h
 *
 * [EOF]
 */
