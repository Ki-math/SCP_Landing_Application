/*
 * File: _coder_gncCore_lib_mex.c
 *
 * MATLAB Coder version            : 24.2
 * C/C++ source code generated on  : 2026/08/28 22:18:33
 */

/* Include Files */
#include "_coder_gncCore_lib_mex.h"
#include "_coder_gncCore_lib_api.h"

/* Function Definitions */
/*
 * Arguments    : int32_T nlhs
 *                mxArray *plhs[]
 *                int32_T nrhs
 *                const mxArray *prhs[]
 * Return Type  : void
 */
void mexFunction(int32_T nlhs, mxArray *plhs[], int32_T nrhs,
                 const mxArray *prhs[])
{
  emlrtStack st = {
      NULL, /* site */
      NULL, /* tls */
      NULL  /* prev */
  };
  const mxArray *b_prhs[14];
  const mxArray *c_prhs[7];
  int32_T i;
  int32_T i1;
  const char_T *entryPointTemplateNames[2] = {"scpk.planIterEmb",
                                              "scpk.trackStepEmb"};
  mexAtExit(&gncCore_lib_atexit);
  gncCore_lib_initialize();
  st.tls = emlrtRootTLSGlobal;
  switch (emlrtGetEntryPointIndexR2016a(
      &st, nrhs, &prhs[0], (const char_T **)&entryPointTemplateNames[0], 2)) {
  case 0:
    for (i = 0; i < 14; i++) {
      b_prhs[i] = prhs[i + 1];
    }
    unsafe_scpk_planIterEmb_mexFunction(nlhs, plhs, nrhs - 1, b_prhs);
    break;
  case 1:
    for (i1 = 0; i1 < 7; i1++) {
      c_prhs[i1] = prhs[i1 + 1];
    }
    unsafe_scpk_trackStepEmb_mexFunction(nlhs, plhs, nrhs - 1, c_prhs);
    break;
  }
  gncCore_lib_terminate();
}

/*
 * Arguments    : void
 * Return Type  : emlrtCTX
 */
emlrtCTX mexFunctionCreateRootTLS(void)
{
  emlrtCreateRootTLSR2022a(&emlrtRootTLSGlobal, &emlrtContextGlobal, NULL, 1,
                           NULL, "Shift_JIS", true);
  return emlrtRootTLSGlobal;
}

/*
 * Arguments    : int32_T nlhs
 *                mxArray *plhs[9]
 *                int32_T nrhs
 *                const mxArray *prhs[14]
 * Return Type  : void
 */
void unsafe_scpk_planIterEmb_mexFunction(int32_T nlhs, mxArray *plhs[9],
                                         int32_T nrhs, const mxArray *prhs[14])
{
  emlrtStack st = {
      NULL, /* site */
      NULL, /* tls */
      NULL  /* prev */
  };
  const mxArray *b_prhs[14];
  const mxArray *outputs[9];
  int32_T i;
  int32_T i1;
  st.tls = emlrtRootTLSGlobal;
  /* Check for proper number of arguments. */
  if (nrhs != 14) {
    emlrtErrMsgIdAndTxt(&st, "EMLRT:runTime:WrongNumberOfInputs", 5, 12, 14, 4,
                        16, "scpk.planIterEmb");
  }
  if (nlhs > 9) {
    emlrtErrMsgIdAndTxt(&st, "EMLRT:runTime:TooManyOutputArguments", 3, 4, 16,
                        "scpk.planIterEmb");
  }
  /* Call the function. */
  for (i = 0; i < 14; i++) {
    b_prhs[i] = prhs[i];
  }
  scpk_planIterEmb_api(b_prhs, nlhs, outputs);
  /* Copy over outputs to the caller. */
  if (nlhs < 1) {
    i1 = 1;
  } else {
    i1 = nlhs;
  }
  emlrtReturnArrays(i1, &plhs[0], &outputs[0]);
}

/*
 * Arguments    : int32_T nlhs
 *                mxArray *plhs[5]
 *                int32_T nrhs
 *                const mxArray *prhs[7]
 * Return Type  : void
 */
void unsafe_scpk_trackStepEmb_mexFunction(int32_T nlhs, mxArray *plhs[5],
                                          int32_T nrhs, const mxArray *prhs[7])
{
  emlrtStack st = {
      NULL, /* site */
      NULL, /* tls */
      NULL  /* prev */
  };
  const mxArray *b_prhs[7];
  const mxArray *outputs[5];
  int32_T i;
  int32_T i1;
  st.tls = emlrtRootTLSGlobal;
  /* Check for proper number of arguments. */
  if (nrhs != 7) {
    emlrtErrMsgIdAndTxt(&st, "EMLRT:runTime:WrongNumberOfInputs", 5, 12, 7, 4,
                        17, "scpk.trackStepEmb");
  }
  if (nlhs > 5) {
    emlrtErrMsgIdAndTxt(&st, "EMLRT:runTime:TooManyOutputArguments", 3, 4, 17,
                        "scpk.trackStepEmb");
  }
  /* Call the function. */
  for (i = 0; i < 7; i++) {
    b_prhs[i] = prhs[i];
  }
  scpk_trackStepEmb_api(b_prhs, nlhs, outputs);
  /* Copy over outputs to the caller. */
  if (nlhs < 1) {
    i1 = 1;
  } else {
    i1 = nlhs;
  }
  emlrtReturnArrays(i1, &plhs[0], &outputs[0]);
}

/*
 * File trailer for _coder_gncCore_lib_mex.c
 *
 * [EOF]
 */
