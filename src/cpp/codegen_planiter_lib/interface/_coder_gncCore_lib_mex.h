/*
 * File: _coder_gncCore_lib_mex.h
 *
 * MATLAB Coder version            : 24.2
 * C/C++ source code generated on  : 2026/08/29 00:13:12
 */

#ifndef _CODER_GNCCORE_LIB_MEX_H
#define _CODER_GNCCORE_LIB_MEX_H

/* Include Files */
#include "emlrt.h"
#include "mex.h"
#include "tmwtypes.h"

#ifdef __cplusplus
extern "C" {
#endif

/* Function Declarations */
MEXFUNCTION_LINKAGE void mexFunction(int32_T nlhs, mxArray *plhs[],
                                     int32_T nrhs, const mxArray *prhs[]);

emlrtCTX mexFunctionCreateRootTLS(void);

void unsafe_scpk_planIterEmb_mexFunction(int32_T nlhs, mxArray *plhs[9],
                                         int32_T nrhs, const mxArray *prhs[14]);

void unsafe_scpk_trackStepEmb_mexFunction(int32_T nlhs, mxArray *plhs[5],
                                          int32_T nrhs, const mxArray *prhs[7]);

#ifdef __cplusplus
}
#endif

#endif
/*
 * File trailer for _coder_gncCore_lib_mex.h
 *
 * [EOF]
 */
