/*
 * File: linDisc6All.h
 *
 * MATLAB Coder version            : 24.2
 * C/C++ source code generated on  : 2026/08/29 00:13:12
 */

#ifndef LINDISC6ALL_H
#define LINDISC6ALL_H

/* Include Files */
#include "gncCore_lib_types.h"
#include "rtwtypes.h"
#include <stddef.h>
#include <stdlib.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Function Declarations */
void linDisc6All(const double xl_data[], const double ul_data[],
                 const int ul_size[2], const double sigl_data[],
                 const double phase_data[], const double dtv_data[],
                 const struct0_T *cfg, emxArray_real_T *Ad, emxArray_real_T *Bd,
                 double Sd_data[], int Sd_size[2], double cd_data[],
                 int cd_size[2]);

#ifdef __cplusplus
}
#endif

#endif
/*
 * File trailer for linDisc6All.h
 *
 * [EOF]
 */
