/*
 * File: gncCore_lib_emxutil.h
 *
 * MATLAB Coder version            : 24.2
 * C/C++ source code generated on  : 2026/08/29 11:14:48
 */

#ifndef GNCCORE_LIB_EMXUTIL_H
#define GNCCORE_LIB_EMXUTIL_H

/* Include Files */
#include "gncCore_lib_types.h"
#include "rtwtypes.h"
#include <stddef.h>
#include <stdlib.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Function Declarations */
extern void emxEnsureCapacity_real_T(emxArray_real_T *emxArray, int oldNumel);

extern void emxFree_real_T(emxArray_real_T **pEmxArray);

extern void emxInit_real_T(emxArray_real_T **pEmxArray, int numDimensions);

#ifdef __cplusplus
}
#endif

#endif
/*
 * File trailer for gncCore_lib_emxutil.h
 *
 * [EOF]
 */
