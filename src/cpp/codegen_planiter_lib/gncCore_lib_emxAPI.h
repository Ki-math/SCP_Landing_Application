/*
 * File: gncCore_lib_emxAPI.h
 *
 * MATLAB Coder version            : 24.2
 * C/C++ source code generated on  : 2026/08/28 19:09:09
 */

#ifndef GNCCORE_LIB_EMXAPI_H
#define GNCCORE_LIB_EMXAPI_H

/* Include Files */
#include "gncCore_lib_types.h"
#include "rtwtypes.h"
#include <stddef.h>
#include <stdlib.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Function Declarations */
extern emxArray_real_T *emxCreateND_real_T(int numDimensions, const int *size);

extern emxArray_real_T *
emxCreateWrapperND_real_T(double *data, int numDimensions, const int *size);

extern emxArray_real_T *emxCreateWrapper_real_T(double *data, int rows,
                                                int cols);

extern emxArray_real_T *emxCreate_real_T(int rows, int cols);

extern void emxDestroyArray_real_T(emxArray_real_T *emxArray);

extern void emxInitArray_real_T(emxArray_real_T **pEmxArray, int numDimensions);

#ifdef __cplusplus
}
#endif

#endif
/*
 * File trailer for gncCore_lib_emxAPI.h
 *
 * [EOF]
 */
