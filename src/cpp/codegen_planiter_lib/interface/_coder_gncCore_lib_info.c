/*
 * File: _coder_gncCore_lib_info.c
 *
 * MATLAB Coder version            : 24.2
 * C/C++ source code generated on  : 2026/08/29 00:13:12
 */

/* Include Files */
#include "_coder_gncCore_lib_info.h"
#include "emlrt.h"
#include "tmwtypes.h"

/* Function Declarations */
static const mxArray *c_emlrtMexFcnResolvedFunctionsI(void);

/* Function Definitions */
/*
 * Arguments    : void
 * Return Type  : const mxArray *
 */
static const mxArray *c_emlrtMexFcnResolvedFunctionsI(void)
{
  const mxArray *nameCaptureInfo;
  const char_T *data[6] = {
      "789ced57cb4e1b31147510ad902a202bd6ac90502b54b56190ba234f82a0420a6a9a3214"
      "128f214e3c9ea9c70384158beebb43f013f427fa0b5df647ba6ae699"
      "89252b23529987e66e6e8e4ee273723d3e23835c7d3707005800412d2f057d3ec4f9b0cf"
      "80f112f95cd867051cd58b909917f81f618716e5e8820780b64d14ff",
      "d2b04c4cdb94ef0f6c0418722c72860c9f39c104ed63133592e0a387cc6a828a8147799f"
      "4b5d04fb0dd704aceb8c1c922488e77123f9bfb360bc64f3d024f3c8"
      "0bfc41e5b0f4416f5aacaf3bd03e226d6a607a7a6433ab8720d71d06f5d743a2afdb43aa"
      "ce11ab989d3573e4d39ed2a788459f51f73cac114ccbd881da262191",
      "fef194fa2fa5fa01e370e642fe88f7253193e4be1c4b7c2ca6f429f6d1f7e7fcfe66f58f"
      "4fa9d203b733bf95ea85f5507a1792f5d23e674b12bdbcc06f683d5c"
      "2ad5bed5ddf75bd5f5cea0523cff52a88e7cec4dd099e40348b0aaf59fca799d36471704"
      "2cfa8c783f478dc1f04d87a1a34d7ebe1f6b8e16a47ae37cea7d8967",
      "e2ed8aba73ff4b539ba3e4eefaa74abda89e7b8ebec5b56deb5d738fd63eb7d027abda19"
      "f4b677ca598e3eb51c5d14b0e833e2831c1d1a6088e34ba42c470dcb"
      "ed10f4fff6655daa37cea7cfd178267e90aa3af77f57d4e6e8d5d757df55ea45f5dc73b4"
      "5cbcdcda75b516c505edacd9c59badf362a192e568b4de8664fdbcc0",
      "a73eaf9cb561bfc1911d5cecb37bfdfdf4b27bfdfdf4b27b7d50d9bd3eddfaff00c22c3d"
      "4a",
      ""};
  nameCaptureInfo = NULL;
  emlrtNameCaptureMxArrayR2016a(&data[0], 5688U, &nameCaptureInfo);
  return nameCaptureInfo;
}

/*
 * Arguments    : void
 * Return Type  : mxArray *
 */
mxArray *emlrtMexFcnProperties(void)
{
  mxArray *xEntryPoints;
  mxArray *xInputs;
  mxArray *xResult;
  const char_T *propFieldName[9] = {"Version",
                                    "ResolvedFunctions",
                                    "Checksum",
                                    "EntryPoints",
                                    "CoverageInfo",
                                    "IsPolymorphic",
                                    "PropertyList",
                                    "UUID",
                                    "ClassEntryPointIsHandle"};
  const char_T *epFieldName[8] = {
      "QualifiedName",    "NumberOfInputs", "NumberOfOutputs", "ConstantInputs",
      "ResolvedFilePath", "TimeStamp",      "Constructor",     "Visible"};
  xEntryPoints =
      emlrtCreateStructMatrix(1, 2, 8, (const char_T **)&epFieldName[0]);
  xInputs = emlrtCreateLogicalMatrix(1, 14);
  emlrtSetField(xEntryPoints, 0, "QualifiedName",
                emlrtMxCreateString("scpk.planIterEmb"));
  emlrtSetField(xEntryPoints, 0, "NumberOfInputs",
                emlrtMxCreateDoubleScalar(14.0));
  emlrtSetField(xEntryPoints, 0, "NumberOfOutputs",
                emlrtMxCreateDoubleScalar(9.0));
  emlrtSetField(xEntryPoints, 0, "ConstantInputs", xInputs);
  emlrtSetField(
      xEntryPoints, 0, "ResolvedFilePath",
      emlrtMxCreateString(
          "C:\\Work\\scp_landing_project\\src\\+scpk\\planIterEmb.m"));
  emlrtSetField(xEntryPoints, 0, "TimeStamp",
                emlrtMxCreateDoubleScalar(740222.59476851847));
  emlrtSetField(xEntryPoints, 0, "Constructor",
                emlrtMxCreateLogicalScalar(false));
  emlrtSetField(xEntryPoints, 0, "Visible", emlrtMxCreateLogicalScalar(true));
  xInputs = emlrtCreateLogicalMatrix(1, 7);
  emlrtSetField(xEntryPoints, 1, "QualifiedName",
                emlrtMxCreateString("scpk.trackStepEmb"));
  emlrtSetField(xEntryPoints, 1, "NumberOfInputs",
                emlrtMxCreateDoubleScalar(7.0));
  emlrtSetField(xEntryPoints, 1, "NumberOfOutputs",
                emlrtMxCreateDoubleScalar(5.0));
  emlrtSetField(xEntryPoints, 1, "ConstantInputs", xInputs);
  emlrtSetField(
      xEntryPoints, 1, "ResolvedFilePath",
      emlrtMxCreateString(
          "C:\\Work\\scp_landing_project\\src\\+scpk\\trackStepEmb.m"));
  emlrtSetField(xEntryPoints, 1, "TimeStamp",
                emlrtMxCreateDoubleScalar(740222.79185185186));
  emlrtSetField(xEntryPoints, 1, "Constructor",
                emlrtMxCreateLogicalScalar(false));
  emlrtSetField(xEntryPoints, 1, "Visible", emlrtMxCreateLogicalScalar(true));
  xResult =
      emlrtCreateStructMatrix(1, 1, 9, (const char_T **)&propFieldName[0]);
  emlrtSetField(xResult, 0, "Version",
                emlrtMxCreateString("24.2.0.3212159 (R2024b) Update 9"));
  emlrtSetField(xResult, 0, "ResolvedFunctions",
                (mxArray *)c_emlrtMexFcnResolvedFunctionsI());
  emlrtSetField(xResult, 0, "Checksum",
                emlrtMxCreateString("HutxFLYqo3ACMKfIO7jubC"));
  emlrtSetField(xResult, 0, "EntryPoints", xEntryPoints);
  return xResult;
}

/*
 * File trailer for _coder_gncCore_lib_info.c
 *
 * [EOF]
 */
