/*
 * File: _coder_gncCore_lib_api.c
 *
 * MATLAB Coder version            : 24.2
 * C/C++ source code generated on  : 2026/08/28 19:09:09
 */

/* Include Files */
#include "_coder_gncCore_lib_api.h"
#include "_coder_gncCore_lib_mex.h"

/* Variable Definitions */
emlrtCTX emlrtRootTLSGlobal = NULL;

emlrtContext emlrtContextGlobal = {
    true,                                                 /* bFirstTime */
    false,                                                /* bInitialized */
    131659U,                                              /* fVersionInfo */
    NULL,                                                 /* fErrorFunction */
    "gncCore_lib",                                        /* fFunctionName */
    NULL,                                                 /* fRTCallStack */
    false,                                                /* bDebugMode */
    {2045744189U, 2170104910U, 2743257031U, 4284093946U}, /* fSigWrd */
    NULL                                                  /* fSigMem */
};

/* Function Declarations */
static void ab_emlrt_marshallIn(const emlrtStack *sp, const mxArray *u,
                                const emlrtMsgIdentifier *parentId,
                                real_T y[4]);

static real_T *ac_emlrt_marshallIn(const emlrtStack *sp, const mxArray *src,
                                   const emlrtMsgIdentifier *msgId,
                                   int32_T ret_size[2]);

static real_T (*b_emlrt_marshallIn(const emlrtStack *sp, const mxArray *u,
                                   const emlrtMsgIdentifier *parentId))[14];

static const mxArray *b_emlrt_marshallOut(const int32_T u);

static void bb_emlrt_marshallIn(const emlrtStack *sp, const mxArray *u,
                                const emlrtMsgIdentifier *parentId,
                                real_T y[4]);

static real_T bc_emlrt_marshallIn(const emlrtStack *sp, const mxArray *src,
                                  const emlrtMsgIdentifier *msgId);

static real_T (*c_emlrt_marshallIn(const emlrtStack *sp, const mxArray *nullptr,
                                   const char_T *identifier))[12];

static const mxArray *c_emlrt_marshallOut(const real_T u);

static void cb_emlrt_marshallIn(const emlrtStack *sp, const mxArray *u,
                                const emlrtMsgIdentifier *parentId,
                                real_T y[2]);

static void cc_emlrt_marshallIn(const emlrtStack *sp, const mxArray *src,
                                const emlrtMsgIdentifier *msgId, real_T ret[9]);

static real_T (*d_emlrt_marshallIn(const emlrtStack *sp, const mxArray *u,
                                   const emlrtMsgIdentifier *parentId))[12];

static const mxArray *d_emlrt_marshallOut(emxArray_real_T *u);

static void db_emlrt_marshallIn(const emlrtStack *sp, const mxArray *nullptr,
                                const char_T *identifier, struct4_T *y);

static void dc_emlrt_marshallIn(const emlrtStack *sp, const mxArray *src,
                                const emlrtMsgIdentifier *msgId, real_T ret[3]);

static real_T *e_emlrt_marshallIn(const emlrtStack *sp, const mxArray *nullptr,
                                  const char_T *identifier, int32_T y_size[2]);

static const mxArray *e_emlrt_marshallOut(real_T u[7]);

static void eb_emlrt_marshallIn(const emlrtStack *sp, const mxArray *u,
                                const emlrtMsgIdentifier *parentId,
                                struct4_T *y);

static void ec_emlrt_marshallIn(const emlrtStack *sp, const mxArray *src,
                                const emlrtMsgIdentifier *msgId,
                                real_T ret[12]);

static void emlrtExitTimeCleanupDtorFcn(const void *r);

static real_T (*emlrt_marshallIn(const emlrtStack *sp, const mxArray *nullptr,
                                 const char_T *identifier))[14];

static const mxArray *emlrt_marshallOut(real_T u_data[],
                                        const int32_T u_size[2]);

static void emxEnsureCapacity_real_T(emxArray_real_T *emxArray,
                                     int32_T oldNumel);

static void emxFree_real_T(const emlrtStack *sp, emxArray_real_T **pEmxArray);

static void emxInit_real_T(const emlrtStack *sp, emxArray_real_T **pEmxArray);

static real_T *f_emlrt_marshallIn(const emlrtStack *sp, const mxArray *u,
                                  const emlrtMsgIdentifier *parentId,
                                  int32_T y_size[2]);

static const mxArray *f_emlrt_marshallOut(real_T u_data[],
                                          const int32_T *u_size);

static void fb_emlrt_marshallIn(const emlrtStack *sp, const mxArray *nullptr,
                                const char_T *identifier, emxArray_real_T *y);

static void fc_emlrt_marshallIn(const emlrtStack *sp, const mxArray *src,
                                const emlrtMsgIdentifier *msgId, real_T ret[8]);

static real_T *g_emlrt_marshallIn(const emlrtStack *sp, const mxArray *nullptr,
                                  const char_T *identifier, int32_T y_size[2]);

static const mxArray *g_emlrt_marshallOut(real_T u[4]);

static void gb_emlrt_marshallIn(const emlrtStack *sp, const mxArray *u,
                                const emlrtMsgIdentifier *parentId,
                                emxArray_real_T *y);

static void gc_emlrt_marshallIn(const emlrtStack *sp, const mxArray *src,
                                const emlrtMsgIdentifier *msgId, real_T ret[4]);

static real_T *h_emlrt_marshallIn(const emlrtStack *sp, const mxArray *u,
                                  const emlrtMsgIdentifier *parentId,
                                  int32_T y_size[2]);

static real_T *hb_emlrt_marshallIn(const emlrtStack *sp, const mxArray *nullptr,
                                   const char_T *identifier, int32_T y_size[2]);

static void hc_emlrt_marshallIn(const emlrtStack *sp, const mxArray *src,
                                const emlrtMsgIdentifier *msgId, real_T ret[4]);

static real_T *i_emlrt_marshallIn(const emlrtStack *sp, const mxArray *nullptr,
                                  const char_T *identifier, int32_T y_size[2]);

static real_T *ib_emlrt_marshallIn(const emlrtStack *sp, const mxArray *u,
                                   const emlrtMsgIdentifier *parentId,
                                   int32_T y_size[2]);

static void ic_emlrt_marshallIn(const emlrtStack *sp, const mxArray *src,
                                const emlrtMsgIdentifier *msgId, real_T ret[2]);

static real_T *j_emlrt_marshallIn(const emlrtStack *sp, const mxArray *u,
                                  const emlrtMsgIdentifier *parentId,
                                  int32_T y_size[2]);

static real_T *jb_emlrt_marshallIn(const emlrtStack *sp, const mxArray *nullptr,
                                   const char_T *identifier, int32_T y_size[2]);

static void jc_emlrt_marshallIn(const emlrtStack *sp, const mxArray *src,
                                const emlrtMsgIdentifier *msgId,
                                emxArray_real_T *ret);

static real_T *k_emlrt_marshallIn(const emlrtStack *sp, const mxArray *nullptr,
                                  const char_T *identifier, int32_T y_size[2]);

static real_T *kb_emlrt_marshallIn(const emlrtStack *sp, const mxArray *u,
                                   const emlrtMsgIdentifier *parentId,
                                   int32_T y_size[2]);

static real_T *kc_emlrt_marshallIn(const emlrtStack *sp, const mxArray *src,
                                   const emlrtMsgIdentifier *msgId,
                                   int32_T ret_size[2]);

static real_T *l_emlrt_marshallIn(const emlrtStack *sp, const mxArray *u,
                                  const emlrtMsgIdentifier *parentId,
                                  int32_T y_size[2]);

static real_T *lb_emlrt_marshallIn(const emlrtStack *sp, const mxArray *nullptr,
                                   const char_T *identifier, int32_T y_size[2]);

static real_T *lc_emlrt_marshallIn(const emlrtStack *sp, const mxArray *src,
                                   const emlrtMsgIdentifier *msgId,
                                   int32_T ret_size[2]);

static real_T *m_emlrt_marshallIn(const emlrtStack *sp, const mxArray *nullptr,
                                  const char_T *identifier, int32_T y_size[2]);

static real_T *mb_emlrt_marshallIn(const emlrtStack *sp, const mxArray *u,
                                   const emlrtMsgIdentifier *parentId,
                                   int32_T y_size[2]);

static real_T *mc_emlrt_marshallIn(const emlrtStack *sp, const mxArray *src,
                                   const emlrtMsgIdentifier *msgId,
                                   int32_T ret_size[2]);

static real_T *n_emlrt_marshallIn(const emlrtStack *sp, const mxArray *u,
                                  const emlrtMsgIdentifier *parentId,
                                  int32_T y_size[2]);

static void nb_emlrt_marshallIn(const emlrtStack *sp, const mxArray *nullptr,
                                const char_T *identifier, struct5_T *y);

static void nc_emlrt_marshallIn(const emlrtStack *sp, const mxArray *src,
                                const emlrtMsgIdentifier *msgId,
                                real_T ret[14]);

static void o_emlrt_marshallIn(const emlrtStack *sp, const mxArray *nullptr,
                               const char_T *identifier, struct0_T *y);

static void ob_emlrt_marshallIn(const emlrtStack *sp, const mxArray *u,
                                const emlrtMsgIdentifier *parentId,
                                struct5_T *y);

static void oc_emlrt_marshallIn(const emlrtStack *sp, const mxArray *src,
                                const emlrtMsgIdentifier *msgId, real_T ret[7]);

static void p_emlrt_marshallIn(const emlrtStack *sp, const mxArray *u,
                               const emlrtMsgIdentifier *parentId,
                               struct0_T *y);

static void pb_emlrt_marshallIn(const emlrtStack *sp, const mxArray *u,
                                const emlrtMsgIdentifier *parentId,
                                real_T y[14]);

static real_T *pc_emlrt_marshallIn(const emlrtStack *sp, const mxArray *src,
                                   const emlrtMsgIdentifier *msgId,
                                   int32_T *ret_size);

static struct1_T q_emlrt_marshallIn(const emlrtStack *sp, const mxArray *u,
                                    const emlrtMsgIdentifier *parentId);

static void qb_emlrt_marshallIn(const emlrtStack *sp, const mxArray *u,
                                const emlrtMsgIdentifier *parentId,
                                real_T y[7]);

static real_T r_emlrt_marshallIn(const emlrtStack *sp, const mxArray *u,
                                 const emlrtMsgIdentifier *parentId);

static real_T *rb_emlrt_marshallIn(const emlrtStack *sp, const mxArray *nullptr,
                                   const char_T *identifier, int32_T *y_size);

static void s_emlrt_marshallIn(const emlrtStack *sp, const mxArray *u,
                               const emlrtMsgIdentifier *parentId,
                               struct2_T *y);

static real_T *sb_emlrt_marshallIn(const emlrtStack *sp, const mxArray *u,
                                   const emlrtMsgIdentifier *parentId,
                                   int32_T *y_size);

static void t_emlrt_marshallIn(const emlrtStack *sp, const mxArray *u,
                               const emlrtMsgIdentifier *parentId, real_T y[9]);

static real_T (*tb_emlrt_marshallIn(const emlrtStack *sp, const mxArray *src,
                                    const emlrtMsgIdentifier *msgId))[14];

static void u_emlrt_marshallIn(const emlrtStack *sp, const mxArray *u,
                               const emlrtMsgIdentifier *parentId, real_T y[3]);

static real_T (*ub_emlrt_marshallIn(const emlrtStack *sp, const mxArray *src,
                                    const emlrtMsgIdentifier *msgId))[12];

static void v_emlrt_marshallIn(const emlrtStack *sp, const mxArray *u,
                               const emlrtMsgIdentifier *parentId,
                               real_T y[12]);

static real_T *vb_emlrt_marshallIn(const emlrtStack *sp, const mxArray *src,
                                   const emlrtMsgIdentifier *msgId,
                                   int32_T ret_size[2]);

static void w_emlrt_marshallIn(const emlrtStack *sp, const mxArray *u,
                               const emlrtMsgIdentifier *parentId, real_T y[8]);

static real_T *wb_emlrt_marshallIn(const emlrtStack *sp, const mxArray *src,
                                   const emlrtMsgIdentifier *msgId,
                                   int32_T ret_size[2]);

static void x_emlrt_marshallIn(const emlrtStack *sp, const mxArray *nullptr,
                               const char_T *identifier, struct3_T *y);

static real_T *xb_emlrt_marshallIn(const emlrtStack *sp, const mxArray *src,
                                   const emlrtMsgIdentifier *msgId,
                                   int32_T ret_size[2]);

static void y_emlrt_marshallIn(const emlrtStack *sp, const mxArray *u,
                               const emlrtMsgIdentifier *parentId,
                               struct3_T *y);

static real_T *yb_emlrt_marshallIn(const emlrtStack *sp, const mxArray *src,
                                   const emlrtMsgIdentifier *msgId,
                                   int32_T ret_size[2]);

/* Function Definitions */
/*
 * Arguments    : const emlrtStack *sp
 *                const mxArray *u
 *                const emlrtMsgIdentifier *parentId
 *                real_T y[4]
 * Return Type  : void
 */
static void ab_emlrt_marshallIn(const emlrtStack *sp, const mxArray *u,
                                const emlrtMsgIdentifier *parentId, real_T y[4])
{
  gc_emlrt_marshallIn(sp, emlrtAlias(u), parentId, y);
  emlrtDestroyArray(&u);
}

/*
 * Arguments    : const emlrtStack *sp
 *                const mxArray *src
 *                const emlrtMsgIdentifier *msgId
 *                int32_T ret_size[2]
 * Return Type  : real_T *
 */
static real_T *ac_emlrt_marshallIn(const emlrtStack *sp, const mxArray *src,
                                   const emlrtMsgIdentifier *msgId,
                                   int32_T ret_size[2])
{
  static const int32_T dims[2] = {1, 201};
  real_T *ret_data;
  int32_T iv[2];
  boolean_T bv[2] = {false, true};
  emlrtCheckVsBuiltInR2012b((emlrtConstCTX)sp, msgId, src, "double", false, 2U,
                            (const void *)&dims[0], &bv[0], &iv[0]);
  ret_size[0] = iv[0];
  ret_size[1] = iv[1];
  ret_data = (real_T *)emlrtMxGetData(src);
  emlrtDestroyArray(&src);
  return ret_data;
}

/*
 * Arguments    : const emlrtStack *sp
 *                const mxArray *u
 *                const emlrtMsgIdentifier *parentId
 * Return Type  : real_T (*)[14]
 */
static real_T (*b_emlrt_marshallIn(const emlrtStack *sp, const mxArray *u,
                                   const emlrtMsgIdentifier *parentId))[14]
{
  real_T(*y)[14];
  y = tb_emlrt_marshallIn(sp, emlrtAlias(u), parentId);
  emlrtDestroyArray(&u);
  return y;
}

/*
 * Arguments    : const int32_T u
 * Return Type  : const mxArray *
 */
static const mxArray *b_emlrt_marshallOut(const int32_T u)
{
  const mxArray *m;
  const mxArray *y;
  y = NULL;
  m = emlrtCreateNumericMatrix(1, 1, mxINT32_CLASS, mxREAL);
  *(int32_T *)emlrtMxGetData(m) = u;
  emlrtAssign(&y, m);
  return y;
}

/*
 * Arguments    : const emlrtStack *sp
 *                const mxArray *u
 *                const emlrtMsgIdentifier *parentId
 *                real_T y[4]
 * Return Type  : void
 */
static void bb_emlrt_marshallIn(const emlrtStack *sp, const mxArray *u,
                                const emlrtMsgIdentifier *parentId, real_T y[4])
{
  hc_emlrt_marshallIn(sp, emlrtAlias(u), parentId, y);
  emlrtDestroyArray(&u);
}

/*
 * Arguments    : const emlrtStack *sp
 *                const mxArray *src
 *                const emlrtMsgIdentifier *msgId
 * Return Type  : real_T
 */
static real_T bc_emlrt_marshallIn(const emlrtStack *sp, const mxArray *src,
                                  const emlrtMsgIdentifier *msgId)
{
  static const int32_T dims = 0;
  real_T ret;
  emlrtCheckBuiltInR2012b((emlrtConstCTX)sp, msgId, src, "double", false, 0U,
                          (const void *)&dims);
  ret = *(real_T *)emlrtMxGetData(src);
  emlrtDestroyArray(&src);
  return ret;
}

/*
 * Arguments    : const emlrtStack *sp
 *                const mxArray *nullptr
 *                const char_T *identifier
 * Return Type  : real_T (*)[12]
 */
static real_T (*c_emlrt_marshallIn(const emlrtStack *sp, const mxArray *nullptr,
                                   const char_T *identifier))[12]
{
  emlrtMsgIdentifier thisId;
  real_T(*y)[12];
  thisId.fIdentifier = (const char_T *)identifier;
  thisId.fParent = NULL;
  thisId.bParentIsCell = false;
  y = d_emlrt_marshallIn(sp, emlrtAlias(nullptr), &thisId);
  emlrtDestroyArray(&nullptr);
  return y;
}

/*
 * Arguments    : const real_T u
 * Return Type  : const mxArray *
 */
static const mxArray *c_emlrt_marshallOut(const real_T u)
{
  const mxArray *m;
  const mxArray *y;
  y = NULL;
  m = emlrtCreateDoubleScalar(u);
  emlrtAssign(&y, m);
  return y;
}

/*
 * Arguments    : const emlrtStack *sp
 *                const mxArray *u
 *                const emlrtMsgIdentifier *parentId
 *                real_T y[2]
 * Return Type  : void
 */
static void cb_emlrt_marshallIn(const emlrtStack *sp, const mxArray *u,
                                const emlrtMsgIdentifier *parentId, real_T y[2])
{
  ic_emlrt_marshallIn(sp, emlrtAlias(u), parentId, y);
  emlrtDestroyArray(&u);
}

/*
 * Arguments    : const emlrtStack *sp
 *                const mxArray *src
 *                const emlrtMsgIdentifier *msgId
 *                real_T ret[9]
 * Return Type  : void
 */
static void cc_emlrt_marshallIn(const emlrtStack *sp, const mxArray *src,
                                const emlrtMsgIdentifier *msgId, real_T ret[9])
{
  static const int32_T dims[2] = {3, 3};
  real_T(*r)[9];
  int32_T i;
  emlrtCheckBuiltInR2012b((emlrtConstCTX)sp, msgId, src, "double", false, 2U,
                          (const void *)&dims[0]);
  r = (real_T(*)[9])emlrtMxGetData(src);
  for (i = 0; i < 9; i++) {
    ret[i] = (*r)[i];
  }
  emlrtDestroyArray(&src);
}

/*
 * Arguments    : const emlrtStack *sp
 *                const mxArray *u
 *                const emlrtMsgIdentifier *parentId
 * Return Type  : real_T (*)[12]
 */
static real_T (*d_emlrt_marshallIn(const emlrtStack *sp, const mxArray *u,
                                   const emlrtMsgIdentifier *parentId))[12]
{
  real_T(*y)[12];
  y = ub_emlrt_marshallIn(sp, emlrtAlias(u), parentId);
  emlrtDestroyArray(&u);
  return y;
}

/*
 * Arguments    : emxArray_real_T *u
 * Return Type  : const mxArray *
 */
static const mxArray *d_emlrt_marshallOut(emxArray_real_T *u)
{
  static const int32_T i = 0;
  const mxArray *m;
  const mxArray *y;
  real_T *u_data;
  u_data = u->data;
  y = NULL;
  m = emlrtCreateNumericArray(1, (const void *)&i, mxDOUBLE_CLASS, mxREAL);
  emlrtMxSetData((mxArray *)m, &u_data[0]);
  emlrtSetDimensions((mxArray *)m, &u->size[0], 1);
  u->canFreeData = false;
  emlrtAssign(&y, m);
  return y;
}

/*
 * Arguments    : const emlrtStack *sp
 *                const mxArray *nullptr
 *                const char_T *identifier
 *                struct4_T *y
 * Return Type  : void
 */
static void db_emlrt_marshallIn(const emlrtStack *sp, const mxArray *nullptr,
                                const char_T *identifier, struct4_T *y)
{
  emlrtMsgIdentifier thisId;
  thisId.fIdentifier = (const char_T *)identifier;
  thisId.fParent = NULL;
  thisId.bParentIsCell = false;
  eb_emlrt_marshallIn(sp, emlrtAlias(nullptr), &thisId, y);
  emlrtDestroyArray(&nullptr);
}

/*
 * Arguments    : const emlrtStack *sp
 *                const mxArray *src
 *                const emlrtMsgIdentifier *msgId
 *                real_T ret[3]
 * Return Type  : void
 */
static void dc_emlrt_marshallIn(const emlrtStack *sp, const mxArray *src,
                                const emlrtMsgIdentifier *msgId, real_T ret[3])
{
  static const int32_T dims = 3;
  real_T(*r)[3];
  emlrtCheckBuiltInR2012b((emlrtConstCTX)sp, msgId, src, "double", false, 1U,
                          (const void *)&dims);
  r = (real_T(*)[3])emlrtMxGetData(src);
  ret[0] = (*r)[0];
  ret[1] = (*r)[1];
  ret[2] = (*r)[2];
  emlrtDestroyArray(&src);
}

/*
 * Arguments    : const emlrtStack *sp
 *                const mxArray *nullptr
 *                const char_T *identifier
 *                int32_T y_size[2]
 * Return Type  : real_T *
 */
static real_T *e_emlrt_marshallIn(const emlrtStack *sp, const mxArray *nullptr,
                                  const char_T *identifier, int32_T y_size[2])
{
  emlrtMsgIdentifier thisId;
  real_T *y_data;
  thisId.fIdentifier = (const char_T *)identifier;
  thisId.fParent = NULL;
  thisId.bParentIsCell = false;
  y_data = f_emlrt_marshallIn(sp, emlrtAlias(nullptr), &thisId, y_size);
  emlrtDestroyArray(&nullptr);
  return y_data;
}

/*
 * Arguments    : real_T u[7]
 * Return Type  : const mxArray *
 */
static const mxArray *e_emlrt_marshallOut(real_T u[7])
{
  static const int32_T i = 0;
  static const int32_T i1 = 7;
  const mxArray *m;
  const mxArray *y;
  y = NULL;
  m = emlrtCreateNumericArray(1, (const void *)&i, mxDOUBLE_CLASS, mxREAL);
  emlrtMxSetData((mxArray *)m, &u[0]);
  emlrtSetDimensions((mxArray *)m, &i1, 1);
  emlrtAssign(&y, m);
  return y;
}

/*
 * Arguments    : const emlrtStack *sp
 *                const mxArray *u
 *                const emlrtMsgIdentifier *parentId
 *                struct4_T *y
 * Return Type  : void
 */
static void eb_emlrt_marshallIn(const emlrtStack *sp, const mxArray *u,
                                const emlrtMsgIdentifier *parentId,
                                struct4_T *y)
{
  static const int32_T dims = 0;
  static const char_T *fieldNames[11] = {
      "maxIter",    "fixedIter", "tolPri",    "tolDua",  "omega",  "rho",
      "checkEvery", "powerIter", "certAfter", "certTol", "certEps"};
  emlrtMsgIdentifier thisId;
  thisId.fParent = parentId;
  thisId.bParentIsCell = false;
  emlrtCheckStructR2012b((emlrtConstCTX)sp, parentId, u, 11,
                         (const char_T **)&fieldNames[0], 0U,
                         (const void *)&dims);
  thisId.fIdentifier = "maxIter";
  y->maxIter = r_emlrt_marshallIn(
      sp,
      emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 0, "maxIter")),
      &thisId);
  thisId.fIdentifier = "fixedIter";
  y->fixedIter = r_emlrt_marshallIn(
      sp,
      emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 1, "fixedIter")),
      &thisId);
  thisId.fIdentifier = "tolPri";
  y->tolPri = r_emlrt_marshallIn(
      sp, emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 2, "tolPri")),
      &thisId);
  thisId.fIdentifier = "tolDua";
  y->tolDua = r_emlrt_marshallIn(
      sp, emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 3, "tolDua")),
      &thisId);
  thisId.fIdentifier = "omega";
  y->omega = r_emlrt_marshallIn(
      sp, emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 4, "omega")),
      &thisId);
  thisId.fIdentifier = "rho";
  y->rho = r_emlrt_marshallIn(
      sp, emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 5, "rho")),
      &thisId);
  thisId.fIdentifier = "checkEvery";
  y->checkEvery = r_emlrt_marshallIn(
      sp,
      emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 6, "checkEvery")),
      &thisId);
  thisId.fIdentifier = "powerIter";
  y->powerIter = r_emlrt_marshallIn(
      sp,
      emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 7, "powerIter")),
      &thisId);
  thisId.fIdentifier = "certAfter";
  y->certAfter = r_emlrt_marshallIn(
      sp,
      emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 8, "certAfter")),
      &thisId);
  thisId.fIdentifier = "certTol";
  y->certTol = r_emlrt_marshallIn(
      sp,
      emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 9, "certTol")),
      &thisId);
  thisId.fIdentifier = "certEps";
  y->certEps = r_emlrt_marshallIn(
      sp,
      emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 10, "certEps")),
      &thisId);
  emlrtDestroyArray(&u);
}

/*
 * Arguments    : const emlrtStack *sp
 *                const mxArray *src
 *                const emlrtMsgIdentifier *msgId
 *                real_T ret[12]
 * Return Type  : void
 */
static void ec_emlrt_marshallIn(const emlrtStack *sp, const mxArray *src,
                                const emlrtMsgIdentifier *msgId, real_T ret[12])
{
  static const int32_T dims[2] = {3, 4};
  real_T(*r)[12];
  int32_T i;
  emlrtCheckBuiltInR2012b((emlrtConstCTX)sp, msgId, src, "double", false, 2U,
                          (const void *)&dims[0]);
  r = (real_T(*)[12])emlrtMxGetData(src);
  for (i = 0; i < 12; i++) {
    ret[i] = (*r)[i];
  }
  emlrtDestroyArray(&src);
}

/*
 * Arguments    : const void *r
 * Return Type  : void
 */
static void emlrtExitTimeCleanupDtorFcn(const void *r)
{
  emlrtExitTimeCleanup(&emlrtContextGlobal);
}

/*
 * Arguments    : const emlrtStack *sp
 *                const mxArray *nullptr
 *                const char_T *identifier
 * Return Type  : real_T (*)[14]
 */
static real_T (*emlrt_marshallIn(const emlrtStack *sp, const mxArray *nullptr,
                                 const char_T *identifier))[14]
{
  emlrtMsgIdentifier thisId;
  real_T(*y)[14];
  thisId.fIdentifier = (const char_T *)identifier;
  thisId.fParent = NULL;
  thisId.bParentIsCell = false;
  y = b_emlrt_marshallIn(sp, emlrtAlias(nullptr), &thisId);
  emlrtDestroyArray(&nullptr);
  return y;
}

/*
 * Arguments    : real_T u_data[]
 *                const int32_T u_size[2]
 * Return Type  : const mxArray *
 */
static const mxArray *emlrt_marshallOut(real_T u_data[],
                                        const int32_T u_size[2])
{
  static const int32_T iv[2] = {0, 0};
  const mxArray *m;
  const mxArray *y;
  y = NULL;
  m = emlrtCreateNumericArray(2, (const void *)&iv[0], mxDOUBLE_CLASS, mxREAL);
  emlrtMxSetData((mxArray *)m, &u_data[0]);
  emlrtSetDimensions((mxArray *)m, &u_size[0], 2);
  emlrtAssign(&y, m);
  return y;
}

/*
 * Arguments    : emxArray_real_T *emxArray
 *                int32_T oldNumel
 * Return Type  : void
 */
static void emxEnsureCapacity_real_T(emxArray_real_T *emxArray,
                                     int32_T oldNumel)
{
  int32_T i;
  int32_T newNumel;
  void *newData;
  if (oldNumel < 0) {
    oldNumel = 0;
  }
  newNumel = 1;
  for (i = 0; i < emxArray->numDimensions; i++) {
    newNumel *= emxArray->size[i];
  }
  if (newNumel > emxArray->allocatedSize) {
    i = emxArray->allocatedSize;
    if (i < 16) {
      i = 16;
    }
    while (i < newNumel) {
      if (i > 1073741823) {
        i = MAX_int32_T;
      } else {
        i *= 2;
      }
    }
    newData = emlrtMallocMex((uint32_T)i * sizeof(real_T));
    if (emxArray->data != NULL) {
      memcpy(newData, emxArray->data, sizeof(real_T) * (uint32_T)oldNumel);
      if (emxArray->canFreeData) {
        emlrtFreeMex(emxArray->data);
      }
    }
    emxArray->data = (real_T *)newData;
    emxArray->allocatedSize = i;
    emxArray->canFreeData = true;
  }
}

/*
 * Arguments    : const emlrtStack *sp
 *                emxArray_real_T **pEmxArray
 * Return Type  : void
 */
static void emxFree_real_T(const emlrtStack *sp, emxArray_real_T **pEmxArray)
{
  if (*pEmxArray != (emxArray_real_T *)NULL) {
    if (((*pEmxArray)->data != (real_T *)NULL) && (*pEmxArray)->canFreeData) {
      emlrtFreeMex((*pEmxArray)->data);
    }
    emlrtFreeMex((*pEmxArray)->size);
    emlrtRemoveHeapReference((emlrtCTX)sp, (void *)pEmxArray);
    emlrtFreeEmxArray(*pEmxArray);
    *pEmxArray = (emxArray_real_T *)NULL;
  }
}

/*
 * Arguments    : const emlrtStack *sp
 *                emxArray_real_T **pEmxArray
 * Return Type  : void
 */
static void emxInit_real_T(const emlrtStack *sp, emxArray_real_T **pEmxArray)
{
  emxArray_real_T *emxArray;
  *pEmxArray = (emxArray_real_T *)emlrtMallocEmxArray(sizeof(emxArray_real_T));
  emlrtPushHeapReferenceStackEmxArray((emlrtCTX)sp, true, (void *)pEmxArray,
                                      (void *)&emxFree_real_T, NULL, NULL,
                                      NULL);
  emxArray = *pEmxArray;
  emxArray->data = (real_T *)NULL;
  emxArray->numDimensions = 1;
  emxArray->size = (int32_T *)emlrtMallocMex(sizeof(int32_T));
  emxArray->allocatedSize = 0;
  emxArray->canFreeData = true;
  emxArray->size[0] = 0;
}

/*
 * Arguments    : const emlrtStack *sp
 *                const mxArray *u
 *                const emlrtMsgIdentifier *parentId
 *                int32_T y_size[2]
 * Return Type  : real_T *
 */
static real_T *f_emlrt_marshallIn(const emlrtStack *sp, const mxArray *u,
                                  const emlrtMsgIdentifier *parentId,
                                  int32_T y_size[2])
{
  real_T *y_data;
  y_data = vb_emlrt_marshallIn(sp, emlrtAlias(u), parentId, y_size);
  emlrtDestroyArray(&u);
  return y_data;
}

/*
 * Arguments    : real_T u_data[]
 *                const int32_T *u_size
 * Return Type  : const mxArray *
 */
static const mxArray *f_emlrt_marshallOut(real_T u_data[],
                                          const int32_T *u_size)
{
  static const int32_T i = 0;
  const mxArray *m;
  const mxArray *y;
  y = NULL;
  m = emlrtCreateNumericArray(1, (const void *)&i, mxDOUBLE_CLASS, mxREAL);
  emlrtMxSetData((mxArray *)m, &u_data[0]);
  emlrtSetDimensions((mxArray *)m, u_size, 1);
  emlrtAssign(&y, m);
  return y;
}

/*
 * Arguments    : const emlrtStack *sp
 *                const mxArray *nullptr
 *                const char_T *identifier
 *                emxArray_real_T *y
 * Return Type  : void
 */
static void fb_emlrt_marshallIn(const emlrtStack *sp, const mxArray *nullptr,
                                const char_T *identifier, emxArray_real_T *y)
{
  emlrtMsgIdentifier thisId;
  thisId.fIdentifier = (const char_T *)identifier;
  thisId.fParent = NULL;
  thisId.bParentIsCell = false;
  gb_emlrt_marshallIn(sp, emlrtAlias(nullptr), &thisId, y);
  emlrtDestroyArray(&nullptr);
}

/*
 * Arguments    : const emlrtStack *sp
 *                const mxArray *src
 *                const emlrtMsgIdentifier *msgId
 *                real_T ret[8]
 * Return Type  : void
 */
static void fc_emlrt_marshallIn(const emlrtStack *sp, const mxArray *src,
                                const emlrtMsgIdentifier *msgId, real_T ret[8])
{
  static const int32_T dims[2] = {1, 8};
  real_T(*r)[8];
  int32_T i;
  emlrtCheckBuiltInR2012b((emlrtConstCTX)sp, msgId, src, "double", false, 2U,
                          (const void *)&dims[0]);
  r = (real_T(*)[8])emlrtMxGetData(src);
  for (i = 0; i < 8; i++) {
    ret[i] = (*r)[i];
  }
  emlrtDestroyArray(&src);
}

/*
 * Arguments    : const emlrtStack *sp
 *                const mxArray *nullptr
 *                const char_T *identifier
 *                int32_T y_size[2]
 * Return Type  : real_T *
 */
static real_T *g_emlrt_marshallIn(const emlrtStack *sp, const mxArray *nullptr,
                                  const char_T *identifier, int32_T y_size[2])
{
  emlrtMsgIdentifier thisId;
  real_T *y_data;
  thisId.fIdentifier = (const char_T *)identifier;
  thisId.fParent = NULL;
  thisId.bParentIsCell = false;
  y_data = h_emlrt_marshallIn(sp, emlrtAlias(nullptr), &thisId, y_size);
  emlrtDestroyArray(&nullptr);
  return y_data;
}

/*
 * Arguments    : real_T u[4]
 * Return Type  : const mxArray *
 */
static const mxArray *g_emlrt_marshallOut(real_T u[4])
{
  static const int32_T i = 0;
  static const int32_T i1 = 4;
  const mxArray *m;
  const mxArray *y;
  y = NULL;
  m = emlrtCreateNumericArray(1, (const void *)&i, mxDOUBLE_CLASS, mxREAL);
  emlrtMxSetData((mxArray *)m, &u[0]);
  emlrtSetDimensions((mxArray *)m, &i1, 1);
  emlrtAssign(&y, m);
  return y;
}

/*
 * Arguments    : const emlrtStack *sp
 *                const mxArray *u
 *                const emlrtMsgIdentifier *parentId
 *                emxArray_real_T *y
 * Return Type  : void
 */
static void gb_emlrt_marshallIn(const emlrtStack *sp, const mxArray *u,
                                const emlrtMsgIdentifier *parentId,
                                emxArray_real_T *y)
{
  jc_emlrt_marshallIn(sp, emlrtAlias(u), parentId, y);
  emlrtDestroyArray(&u);
}

/*
 * Arguments    : const emlrtStack *sp
 *                const mxArray *src
 *                const emlrtMsgIdentifier *msgId
 *                real_T ret[4]
 * Return Type  : void
 */
static void gc_emlrt_marshallIn(const emlrtStack *sp, const mxArray *src,
                                const emlrtMsgIdentifier *msgId, real_T ret[4])
{
  static const int32_T dims[2] = {1, 4};
  real_T(*r)[4];
  emlrtCheckBuiltInR2012b((emlrtConstCTX)sp, msgId, src, "double", false, 2U,
                          (const void *)&dims[0]);
  r = (real_T(*)[4])emlrtMxGetData(src);
  ret[0] = (*r)[0];
  ret[1] = (*r)[1];
  ret[2] = (*r)[2];
  ret[3] = (*r)[3];
  emlrtDestroyArray(&src);
}

/*
 * Arguments    : const emlrtStack *sp
 *                const mxArray *u
 *                const emlrtMsgIdentifier *parentId
 *                int32_T y_size[2]
 * Return Type  : real_T *
 */
static real_T *h_emlrt_marshallIn(const emlrtStack *sp, const mxArray *u,
                                  const emlrtMsgIdentifier *parentId,
                                  int32_T y_size[2])
{
  real_T *y_data;
  y_data = wb_emlrt_marshallIn(sp, emlrtAlias(u), parentId, y_size);
  emlrtDestroyArray(&u);
  return y_data;
}

/*
 * Arguments    : const emlrtStack *sp
 *                const mxArray *nullptr
 *                const char_T *identifier
 *                int32_T y_size[2]
 * Return Type  : real_T *
 */
static real_T *hb_emlrt_marshallIn(const emlrtStack *sp, const mxArray *nullptr,
                                   const char_T *identifier, int32_T y_size[2])
{
  emlrtMsgIdentifier thisId;
  real_T *y_data;
  thisId.fIdentifier = (const char_T *)identifier;
  thisId.fParent = NULL;
  thisId.bParentIsCell = false;
  y_data = ib_emlrt_marshallIn(sp, emlrtAlias(nullptr), &thisId, y_size);
  emlrtDestroyArray(&nullptr);
  return y_data;
}

/*
 * Arguments    : const emlrtStack *sp
 *                const mxArray *src
 *                const emlrtMsgIdentifier *msgId
 *                real_T ret[4]
 * Return Type  : void
 */
static void hc_emlrt_marshallIn(const emlrtStack *sp, const mxArray *src,
                                const emlrtMsgIdentifier *msgId, real_T ret[4])
{
  static const int32_T dims = 4;
  real_T(*r)[4];
  emlrtCheckBuiltInR2012b((emlrtConstCTX)sp, msgId, src, "double", false, 1U,
                          (const void *)&dims);
  r = (real_T(*)[4])emlrtMxGetData(src);
  ret[0] = (*r)[0];
  ret[1] = (*r)[1];
  ret[2] = (*r)[2];
  ret[3] = (*r)[3];
  emlrtDestroyArray(&src);
}

/*
 * Arguments    : const emlrtStack *sp
 *                const mxArray *nullptr
 *                const char_T *identifier
 *                int32_T y_size[2]
 * Return Type  : real_T *
 */
static real_T *i_emlrt_marshallIn(const emlrtStack *sp, const mxArray *nullptr,
                                  const char_T *identifier, int32_T y_size[2])
{
  emlrtMsgIdentifier thisId;
  real_T *y_data;
  thisId.fIdentifier = (const char_T *)identifier;
  thisId.fParent = NULL;
  thisId.bParentIsCell = false;
  y_data = j_emlrt_marshallIn(sp, emlrtAlias(nullptr), &thisId, y_size);
  emlrtDestroyArray(&nullptr);
  return y_data;
}

/*
 * Arguments    : const emlrtStack *sp
 *                const mxArray *u
 *                const emlrtMsgIdentifier *parentId
 *                int32_T y_size[2]
 * Return Type  : real_T *
 */
static real_T *ib_emlrt_marshallIn(const emlrtStack *sp, const mxArray *u,
                                   const emlrtMsgIdentifier *parentId,
                                   int32_T y_size[2])
{
  real_T *y_data;
  y_data = kc_emlrt_marshallIn(sp, emlrtAlias(u), parentId, y_size);
  emlrtDestroyArray(&u);
  return y_data;
}

/*
 * Arguments    : const emlrtStack *sp
 *                const mxArray *src
 *                const emlrtMsgIdentifier *msgId
 *                real_T ret[2]
 * Return Type  : void
 */
static void ic_emlrt_marshallIn(const emlrtStack *sp, const mxArray *src,
                                const emlrtMsgIdentifier *msgId, real_T ret[2])
{
  static const int32_T dims[2] = {1, 2};
  real_T(*r)[2];
  emlrtCheckBuiltInR2012b((emlrtConstCTX)sp, msgId, src, "double", false, 2U,
                          (const void *)&dims[0]);
  r = (real_T(*)[2])emlrtMxGetData(src);
  ret[0] = (*r)[0];
  ret[1] = (*r)[1];
  emlrtDestroyArray(&src);
}

/*
 * Arguments    : const emlrtStack *sp
 *                const mxArray *u
 *                const emlrtMsgIdentifier *parentId
 *                int32_T y_size[2]
 * Return Type  : real_T *
 */
static real_T *j_emlrt_marshallIn(const emlrtStack *sp, const mxArray *u,
                                  const emlrtMsgIdentifier *parentId,
                                  int32_T y_size[2])
{
  real_T *y_data;
  y_data = xb_emlrt_marshallIn(sp, emlrtAlias(u), parentId, y_size);
  emlrtDestroyArray(&u);
  return y_data;
}

/*
 * Arguments    : const emlrtStack *sp
 *                const mxArray *nullptr
 *                const char_T *identifier
 *                int32_T y_size[2]
 * Return Type  : real_T *
 */
static real_T *jb_emlrt_marshallIn(const emlrtStack *sp, const mxArray *nullptr,
                                   const char_T *identifier, int32_T y_size[2])
{
  emlrtMsgIdentifier thisId;
  real_T *y_data;
  thisId.fIdentifier = (const char_T *)identifier;
  thisId.fParent = NULL;
  thisId.bParentIsCell = false;
  y_data = kb_emlrt_marshallIn(sp, emlrtAlias(nullptr), &thisId, y_size);
  emlrtDestroyArray(&nullptr);
  return y_data;
}

/*
 * Arguments    : const emlrtStack *sp
 *                const mxArray *src
 *                const emlrtMsgIdentifier *msgId
 *                emxArray_real_T *ret
 * Return Type  : void
 */
static void jc_emlrt_marshallIn(const emlrtStack *sp, const mxArray *src,
                                const emlrtMsgIdentifier *msgId,
                                emxArray_real_T *ret)
{
  static const int32_T dims = 12000;
  int32_T i;
  int32_T i1;
  boolean_T b = true;
  emlrtCheckVsBuiltInR2012b((emlrtConstCTX)sp, msgId, src, "double", false, 1U,
                            (const void *)&dims, &b, &i);
  ret->allocatedSize = i;
  i1 = ret->size[0];
  ret->size[0] = i;
  emxEnsureCapacity_real_T(ret, i1);
  ret->data = (real_T *)emlrtMxGetData(src);
  ret->canFreeData = false;
  emlrtDestroyArray(&src);
}

/*
 * Arguments    : const emlrtStack *sp
 *                const mxArray *nullptr
 *                const char_T *identifier
 *                int32_T y_size[2]
 * Return Type  : real_T *
 */
static real_T *k_emlrt_marshallIn(const emlrtStack *sp, const mxArray *nullptr,
                                  const char_T *identifier, int32_T y_size[2])
{
  emlrtMsgIdentifier thisId;
  real_T *y_data;
  thisId.fIdentifier = (const char_T *)identifier;
  thisId.fParent = NULL;
  thisId.bParentIsCell = false;
  y_data = l_emlrt_marshallIn(sp, emlrtAlias(nullptr), &thisId, y_size);
  emlrtDestroyArray(&nullptr);
  return y_data;
}

/*
 * Arguments    : const emlrtStack *sp
 *                const mxArray *u
 *                const emlrtMsgIdentifier *parentId
 *                int32_T y_size[2]
 * Return Type  : real_T *
 */
static real_T *kb_emlrt_marshallIn(const emlrtStack *sp, const mxArray *u,
                                   const emlrtMsgIdentifier *parentId,
                                   int32_T y_size[2])
{
  real_T *y_data;
  y_data = lc_emlrt_marshallIn(sp, emlrtAlias(u), parentId, y_size);
  emlrtDestroyArray(&u);
  return y_data;
}

/*
 * Arguments    : const emlrtStack *sp
 *                const mxArray *src
 *                const emlrtMsgIdentifier *msgId
 *                int32_T ret_size[2]
 * Return Type  : real_T *
 */
static real_T *kc_emlrt_marshallIn(const emlrtStack *sp, const mxArray *src,
                                   const emlrtMsgIdentifier *msgId,
                                   int32_T ret_size[2])
{
  static const int32_T dims[2] = {14, 61};
  real_T *ret_data;
  int32_T iv[2];
  boolean_T bv[2] = {false, true};
  emlrtCheckVsBuiltInR2012b((emlrtConstCTX)sp, msgId, src, "double", false, 2U,
                            (const void *)&dims[0], &bv[0], &iv[0]);
  ret_size[0] = iv[0];
  ret_size[1] = iv[1];
  ret_data = (real_T *)emlrtMxGetData(src);
  emlrtDestroyArray(&src);
  return ret_data;
}

/*
 * Arguments    : const emlrtStack *sp
 *                const mxArray *u
 *                const emlrtMsgIdentifier *parentId
 *                int32_T y_size[2]
 * Return Type  : real_T *
 */
static real_T *l_emlrt_marshallIn(const emlrtStack *sp, const mxArray *u,
                                  const emlrtMsgIdentifier *parentId,
                                  int32_T y_size[2])
{
  real_T *y_data;
  y_data = yb_emlrt_marshallIn(sp, emlrtAlias(u), parentId, y_size);
  emlrtDestroyArray(&u);
  return y_data;
}

/*
 * Arguments    : const emlrtStack *sp
 *                const mxArray *nullptr
 *                const char_T *identifier
 *                int32_T y_size[2]
 * Return Type  : real_T *
 */
static real_T *lb_emlrt_marshallIn(const emlrtStack *sp, const mxArray *nullptr,
                                   const char_T *identifier, int32_T y_size[2])
{
  emlrtMsgIdentifier thisId;
  real_T *y_data;
  thisId.fIdentifier = (const char_T *)identifier;
  thisId.fParent = NULL;
  thisId.bParentIsCell = false;
  y_data = mb_emlrt_marshallIn(sp, emlrtAlias(nullptr), &thisId, y_size);
  emlrtDestroyArray(&nullptr);
  return y_data;
}

/*
 * Arguments    : const emlrtStack *sp
 *                const mxArray *src
 *                const emlrtMsgIdentifier *msgId
 *                int32_T ret_size[2]
 * Return Type  : real_T *
 */
static real_T *lc_emlrt_marshallIn(const emlrtStack *sp, const mxArray *src,
                                   const emlrtMsgIdentifier *msgId,
                                   int32_T ret_size[2])
{
  static const int32_T dims[2] = {7, 60};
  real_T *ret_data;
  int32_T iv[2];
  boolean_T bv[2] = {false, true};
  emlrtCheckVsBuiltInR2012b((emlrtConstCTX)sp, msgId, src, "double", false, 2U,
                            (const void *)&dims[0], &bv[0], &iv[0]);
  ret_size[0] = iv[0];
  ret_size[1] = iv[1];
  ret_data = (real_T *)emlrtMxGetData(src);
  emlrtDestroyArray(&src);
  return ret_data;
}

/*
 * Arguments    : const emlrtStack *sp
 *                const mxArray *nullptr
 *                const char_T *identifier
 *                int32_T y_size[2]
 * Return Type  : real_T *
 */
static real_T *m_emlrt_marshallIn(const emlrtStack *sp, const mxArray *nullptr,
                                  const char_T *identifier, int32_T y_size[2])
{
  emlrtMsgIdentifier thisId;
  real_T *y_data;
  thisId.fIdentifier = (const char_T *)identifier;
  thisId.fParent = NULL;
  thisId.bParentIsCell = false;
  y_data = n_emlrt_marshallIn(sp, emlrtAlias(nullptr), &thisId, y_size);
  emlrtDestroyArray(&nullptr);
  return y_data;
}

/*
 * Arguments    : const emlrtStack *sp
 *                const mxArray *u
 *                const emlrtMsgIdentifier *parentId
 *                int32_T y_size[2]
 * Return Type  : real_T *
 */
static real_T *mb_emlrt_marshallIn(const emlrtStack *sp, const mxArray *u,
                                   const emlrtMsgIdentifier *parentId,
                                   int32_T y_size[2])
{
  real_T *y_data;
  y_data = mc_emlrt_marshallIn(sp, emlrtAlias(u), parentId, y_size);
  emlrtDestroyArray(&u);
  return y_data;
}

/*
 * Arguments    : const emlrtStack *sp
 *                const mxArray *src
 *                const emlrtMsgIdentifier *msgId
 *                int32_T ret_size[2]
 * Return Type  : real_T *
 */
static real_T *mc_emlrt_marshallIn(const emlrtStack *sp, const mxArray *src,
                                   const emlrtMsgIdentifier *msgId,
                                   int32_T ret_size[2])
{
  static const int32_T dims[2] = {1, 60};
  real_T *ret_data;
  int32_T iv[2];
  boolean_T bv[2] = {false, true};
  emlrtCheckVsBuiltInR2012b((emlrtConstCTX)sp, msgId, src, "double", false, 2U,
                            (const void *)&dims[0], &bv[0], &iv[0]);
  ret_size[0] = iv[0];
  ret_size[1] = iv[1];
  ret_data = (real_T *)emlrtMxGetData(src);
  emlrtDestroyArray(&src);
  return ret_data;
}

/*
 * Arguments    : const emlrtStack *sp
 *                const mxArray *u
 *                const emlrtMsgIdentifier *parentId
 *                int32_T y_size[2]
 * Return Type  : real_T *
 */
static real_T *n_emlrt_marshallIn(const emlrtStack *sp, const mxArray *u,
                                  const emlrtMsgIdentifier *parentId,
                                  int32_T y_size[2])
{
  real_T *y_data;
  y_data = ac_emlrt_marshallIn(sp, emlrtAlias(u), parentId, y_size);
  emlrtDestroyArray(&u);
  return y_data;
}

/*
 * Arguments    : const emlrtStack *sp
 *                const mxArray *nullptr
 *                const char_T *identifier
 *                struct5_T *y
 * Return Type  : void
 */
static void nb_emlrt_marshallIn(const emlrtStack *sp, const mxArray *nullptr,
                                const char_T *identifier, struct5_T *y)
{
  emlrtMsgIdentifier thisId;
  thisId.fIdentifier = (const char_T *)identifier;
  thisId.fParent = NULL;
  thisId.bParentIsCell = false;
  ob_emlrt_marshallIn(sp, emlrtAlias(nullptr), &thisId, y);
  emlrtDestroyArray(&nullptr);
}

/*
 * Arguments    : const emlrtStack *sp
 *                const mxArray *src
 *                const emlrtMsgIdentifier *msgId
 *                real_T ret[14]
 * Return Type  : void
 */
static void nc_emlrt_marshallIn(const emlrtStack *sp, const mxArray *src,
                                const emlrtMsgIdentifier *msgId, real_T ret[14])
{
  static const int32_T dims = 14;
  real_T(*r)[14];
  int32_T i;
  emlrtCheckBuiltInR2012b((emlrtConstCTX)sp, msgId, src, "double", false, 1U,
                          (const void *)&dims);
  r = (real_T(*)[14])emlrtMxGetData(src);
  for (i = 0; i < 14; i++) {
    ret[i] = (*r)[i];
  }
  emlrtDestroyArray(&src);
}

/*
 * Arguments    : const emlrtStack *sp
 *                const mxArray *nullptr
 *                const char_T *identifier
 *                struct0_T *y
 * Return Type  : void
 */
static void o_emlrt_marshallIn(const emlrtStack *sp, const mxArray *nullptr,
                               const char_T *identifier, struct0_T *y)
{
  emlrtMsgIdentifier thisId;
  thisId.fIdentifier = (const char_T *)identifier;
  thisId.fParent = NULL;
  thisId.bParentIsCell = false;
  p_emlrt_marshallIn(sp, emlrtAlias(nullptr), &thisId, y);
  emlrtDestroyArray(&nullptr);
}

/*
 * Arguments    : const emlrtStack *sp
 *                const mxArray *u
 *                const emlrtMsgIdentifier *parentId
 *                struct5_T *y
 * Return Type  : void
 */
static void ob_emlrt_marshallIn(const emlrtStack *sp, const mxArray *u,
                                const emlrtMsgIdentifier *parentId,
                                struct5_T *y)
{
  static const int32_T dims = 0;
  static const char_T *fieldNames[15] = {
      "dtau",   "Dx",    "Du",      "wx",         "rCtrl",
      "wTerm",  "reg",   "maxIter", "fixedIter",  "tolPri",
      "tolDua", "omega", "rho",     "checkEvery", "powerIter"};
  emlrtMsgIdentifier thisId;
  thisId.fParent = parentId;
  thisId.bParentIsCell = false;
  emlrtCheckStructR2012b((emlrtConstCTX)sp, parentId, u, 15,
                         (const char_T **)&fieldNames[0], 0U,
                         (const void *)&dims);
  thisId.fIdentifier = "dtau";
  y->dtau = r_emlrt_marshallIn(
      sp, emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 0, "dtau")),
      &thisId);
  thisId.fIdentifier = "Dx";
  pb_emlrt_marshallIn(
      sp, emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 1, "Dx")),
      &thisId, y->Dx);
  thisId.fIdentifier = "Du";
  qb_emlrt_marshallIn(
      sp, emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 2, "Du")),
      &thisId, y->Du);
  thisId.fIdentifier = "wx";
  pb_emlrt_marshallIn(
      sp, emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 3, "wx")),
      &thisId, y->wx);
  thisId.fIdentifier = "rCtrl";
  y->rCtrl = r_emlrt_marshallIn(
      sp, emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 4, "rCtrl")),
      &thisId);
  thisId.fIdentifier = "wTerm";
  y->wTerm = r_emlrt_marshallIn(
      sp, emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 5, "wTerm")),
      &thisId);
  thisId.fIdentifier = "reg";
  y->reg = r_emlrt_marshallIn(
      sp, emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 6, "reg")),
      &thisId);
  thisId.fIdentifier = "maxIter";
  y->maxIter = r_emlrt_marshallIn(
      sp,
      emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 7, "maxIter")),
      &thisId);
  thisId.fIdentifier = "fixedIter";
  y->fixedIter = r_emlrt_marshallIn(
      sp,
      emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 8, "fixedIter")),
      &thisId);
  thisId.fIdentifier = "tolPri";
  y->tolPri = r_emlrt_marshallIn(
      sp, emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 9, "tolPri")),
      &thisId);
  thisId.fIdentifier = "tolDua";
  y->tolDua = r_emlrt_marshallIn(
      sp,
      emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 10, "tolDua")),
      &thisId);
  thisId.fIdentifier = "omega";
  y->omega = r_emlrt_marshallIn(
      sp, emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 11, "omega")),
      &thisId);
  thisId.fIdentifier = "rho";
  y->rho = r_emlrt_marshallIn(
      sp, emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 12, "rho")),
      &thisId);
  thisId.fIdentifier = "checkEvery";
  y->checkEvery =
      r_emlrt_marshallIn(sp,
                         emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0,
                                                        13, "checkEvery")),
                         &thisId);
  thisId.fIdentifier = "powerIter";
  y->powerIter = r_emlrt_marshallIn(
      sp,
      emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 14, "powerIter")),
      &thisId);
  emlrtDestroyArray(&u);
}

/*
 * Arguments    : const emlrtStack *sp
 *                const mxArray *src
 *                const emlrtMsgIdentifier *msgId
 *                real_T ret[7]
 * Return Type  : void
 */
static void oc_emlrt_marshallIn(const emlrtStack *sp, const mxArray *src,
                                const emlrtMsgIdentifier *msgId, real_T ret[7])
{
  static const int32_T dims = 7;
  real_T(*r)[7];
  int32_T i;
  emlrtCheckBuiltInR2012b((emlrtConstCTX)sp, msgId, src, "double", false, 1U,
                          (const void *)&dims);
  r = (real_T(*)[7])emlrtMxGetData(src);
  for (i = 0; i < 7; i++) {
    ret[i] = (*r)[i];
  }
  emlrtDestroyArray(&src);
}

/*
 * Arguments    : const emlrtStack *sp
 *                const mxArray *u
 *                const emlrtMsgIdentifier *parentId
 *                struct0_T *y
 * Return Type  : void
 */
static void p_emlrt_marshallIn(const emlrtStack *sp, const mxArray *u,
                               const emlrtMsgIdentifier *parentId, struct0_T *y)
{
  static const int32_T dims = 0;
  static const char_T *fieldNames[39] = {
      "sc",      "veh",    "m0",        "Fs",      "J",         "Jinv",
      "Jphys",   "Tmin1",  "Tmax1",     "nEng",    "Tmin",      "Tmax",
      "tanGim",  "alpha",  "rT",        "gI",      "cx",        "cy",
      "cz",      "LoverD", "cL",        "rho",     "aeroScale", "surfMode",
      "V2ref",   "Bflap",  "cFlapDrag", "jacStep", "vEps",      "tEps",
      "mhatMin", "wMax",   "hmin",      "atmIsa",  "hPad",      "wOn",
      "wTabH",   "wTabY",  "wTabZ"};
  emlrtMsgIdentifier thisId;
  thisId.fParent = parentId;
  thisId.bParentIsCell = false;
  emlrtCheckStructR2012b((emlrtConstCTX)sp, parentId, u, 39,
                         (const char_T **)&fieldNames[0], 0U,
                         (const void *)&dims);
  thisId.fIdentifier = "sc";
  y->sc = q_emlrt_marshallIn(
      sp, emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 0, "sc")),
      &thisId);
  thisId.fIdentifier = "veh";
  s_emlrt_marshallIn(
      sp, emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 1, "veh")),
      &thisId, &y->veh);
  thisId.fIdentifier = "m0";
  y->m0 = r_emlrt_marshallIn(
      sp, emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 2, "m0")),
      &thisId);
  thisId.fIdentifier = "Fs";
  y->Fs = r_emlrt_marshallIn(
      sp, emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 3, "Fs")),
      &thisId);
  thisId.fIdentifier = "J";
  t_emlrt_marshallIn(
      sp, emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 4, "J")),
      &thisId, y->J);
  thisId.fIdentifier = "Jinv";
  t_emlrt_marshallIn(
      sp, emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 5, "Jinv")),
      &thisId, y->Jinv);
  thisId.fIdentifier = "Jphys";
  t_emlrt_marshallIn(
      sp, emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 6, "Jphys")),
      &thisId, y->Jphys);
  thisId.fIdentifier = "Tmin1";
  y->Tmin1 = r_emlrt_marshallIn(
      sp, emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 7, "Tmin1")),
      &thisId);
  thisId.fIdentifier = "Tmax1";
  y->Tmax1 = r_emlrt_marshallIn(
      sp, emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 8, "Tmax1")),
      &thisId);
  thisId.fIdentifier = "nEng";
  y->nEng = r_emlrt_marshallIn(
      sp, emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 9, "nEng")),
      &thisId);
  thisId.fIdentifier = "Tmin";
  y->Tmin = r_emlrt_marshallIn(
      sp, emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 10, "Tmin")),
      &thisId);
  thisId.fIdentifier = "Tmax";
  y->Tmax = r_emlrt_marshallIn(
      sp, emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 11, "Tmax")),
      &thisId);
  thisId.fIdentifier = "tanGim";
  y->tanGim = r_emlrt_marshallIn(
      sp,
      emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 12, "tanGim")),
      &thisId);
  thisId.fIdentifier = "alpha";
  y->alpha = r_emlrt_marshallIn(
      sp, emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 13, "alpha")),
      &thisId);
  thisId.fIdentifier = "rT";
  u_emlrt_marshallIn(
      sp, emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 14, "rT")),
      &thisId, y->rT);
  thisId.fIdentifier = "gI";
  u_emlrt_marshallIn(
      sp, emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 15, "gI")),
      &thisId, y->gI);
  thisId.fIdentifier = "cx";
  y->cx = r_emlrt_marshallIn(
      sp, emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 16, "cx")),
      &thisId);
  thisId.fIdentifier = "cy";
  y->cy = r_emlrt_marshallIn(
      sp, emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 17, "cy")),
      &thisId);
  thisId.fIdentifier = "cz";
  y->cz = r_emlrt_marshallIn(
      sp, emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 18, "cz")),
      &thisId);
  thisId.fIdentifier = "LoverD";
  y->LoverD = r_emlrt_marshallIn(
      sp,
      emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 19, "LoverD")),
      &thisId);
  thisId.fIdentifier = "cL";
  y->cL = r_emlrt_marshallIn(
      sp, emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 20, "cL")),
      &thisId);
  thisId.fIdentifier = "rho";
  y->rho = r_emlrt_marshallIn(
      sp, emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 21, "rho")),
      &thisId);
  thisId.fIdentifier = "aeroScale";
  y->aeroScale = r_emlrt_marshallIn(
      sp,
      emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 22, "aeroScale")),
      &thisId);
  thisId.fIdentifier = "surfMode";
  y->surfMode = r_emlrt_marshallIn(
      sp,
      emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 23, "surfMode")),
      &thisId);
  thisId.fIdentifier = "V2ref";
  y->V2ref = r_emlrt_marshallIn(
      sp, emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 24, "V2ref")),
      &thisId);
  thisId.fIdentifier = "Bflap";
  v_emlrt_marshallIn(
      sp, emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 25, "Bflap")),
      &thisId, y->Bflap);
  thisId.fIdentifier = "cFlapDrag";
  y->cFlapDrag = r_emlrt_marshallIn(
      sp,
      emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 26, "cFlapDrag")),
      &thisId);
  thisId.fIdentifier = "jacStep";
  y->jacStep = r_emlrt_marshallIn(
      sp,
      emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 27, "jacStep")),
      &thisId);
  thisId.fIdentifier = "vEps";
  y->vEps = r_emlrt_marshallIn(
      sp, emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 28, "vEps")),
      &thisId);
  thisId.fIdentifier = "tEps";
  y->tEps = r_emlrt_marshallIn(
      sp, emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 29, "tEps")),
      &thisId);
  thisId.fIdentifier = "mhatMin";
  y->mhatMin = r_emlrt_marshallIn(
      sp,
      emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 30, "mhatMin")),
      &thisId);
  thisId.fIdentifier = "wMax";
  y->wMax = r_emlrt_marshallIn(
      sp, emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 31, "wMax")),
      &thisId);
  thisId.fIdentifier = "hmin";
  y->hmin = r_emlrt_marshallIn(
      sp, emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 32, "hmin")),
      &thisId);
  thisId.fIdentifier = "atmIsa";
  y->atmIsa = r_emlrt_marshallIn(
      sp,
      emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 33, "atmIsa")),
      &thisId);
  thisId.fIdentifier = "hPad";
  y->hPad = r_emlrt_marshallIn(
      sp, emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 34, "hPad")),
      &thisId);
  thisId.fIdentifier = "wOn";
  y->wOn = r_emlrt_marshallIn(
      sp, emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 35, "wOn")),
      &thisId);
  thisId.fIdentifier = "wTabH";
  w_emlrt_marshallIn(
      sp, emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 36, "wTabH")),
      &thisId, y->wTabH);
  thisId.fIdentifier = "wTabY";
  w_emlrt_marshallIn(
      sp, emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 37, "wTabY")),
      &thisId, y->wTabY);
  thisId.fIdentifier = "wTabZ";
  w_emlrt_marshallIn(
      sp, emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 38, "wTabZ")),
      &thisId, y->wTabZ);
  emlrtDestroyArray(&u);
}

/*
 * Arguments    : const emlrtStack *sp
 *                const mxArray *u
 *                const emlrtMsgIdentifier *parentId
 *                real_T y[14]
 * Return Type  : void
 */
static void pb_emlrt_marshallIn(const emlrtStack *sp, const mxArray *u,
                                const emlrtMsgIdentifier *parentId,
                                real_T y[14])
{
  nc_emlrt_marshallIn(sp, emlrtAlias(u), parentId, y);
  emlrtDestroyArray(&u);
}

/*
 * Arguments    : const emlrtStack *sp
 *                const mxArray *src
 *                const emlrtMsgIdentifier *msgId
 *                int32_T *ret_size
 * Return Type  : real_T *
 */
static real_T *pc_emlrt_marshallIn(const emlrtStack *sp, const mxArray *src,
                                   const emlrtMsgIdentifier *msgId,
                                   int32_T *ret_size)
{
  static const int32_T dims = 1300;
  real_T *ret_data;
  boolean_T b = true;
  emlrtCheckVsBuiltInR2012b((emlrtConstCTX)sp, msgId, src, "double", false, 1U,
                            (const void *)&dims, &b, ret_size);
  ret_data = (real_T *)emlrtMxGetData(src);
  emlrtDestroyArray(&src);
  return ret_data;
}

/*
 * Arguments    : const emlrtStack *sp
 *                const mxArray *u
 *                const emlrtMsgIdentifier *parentId
 * Return Type  : struct1_T
 */
static struct1_T q_emlrt_marshallIn(const emlrtStack *sp, const mxArray *u,
                                    const emlrtMsgIdentifier *parentId)
{
  static const int32_T dims = 0;
  static const char_T *fieldNames[4] = {"L", "T", "V", "A"};
  emlrtMsgIdentifier thisId;
  struct1_T y;
  thisId.fParent = parentId;
  thisId.bParentIsCell = false;
  emlrtCheckStructR2012b((emlrtConstCTX)sp, parentId, u, 4,
                         (const char_T **)&fieldNames[0], 0U,
                         (const void *)&dims);
  thisId.fIdentifier = "L";
  y.L = r_emlrt_marshallIn(
      sp, emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 0, "L")),
      &thisId);
  thisId.fIdentifier = "T";
  y.T = r_emlrt_marshallIn(
      sp, emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 1, "T")),
      &thisId);
  thisId.fIdentifier = "V";
  y.V = r_emlrt_marshallIn(
      sp, emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 2, "V")),
      &thisId);
  thisId.fIdentifier = "A";
  y.A = r_emlrt_marshallIn(
      sp, emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 3, "A")),
      &thisId);
  emlrtDestroyArray(&u);
  return y;
}

/*
 * Arguments    : const emlrtStack *sp
 *                const mxArray *u
 *                const emlrtMsgIdentifier *parentId
 *                real_T y[7]
 * Return Type  : void
 */
static void qb_emlrt_marshallIn(const emlrtStack *sp, const mxArray *u,
                                const emlrtMsgIdentifier *parentId, real_T y[7])
{
  oc_emlrt_marshallIn(sp, emlrtAlias(u), parentId, y);
  emlrtDestroyArray(&u);
}

/*
 * Arguments    : const emlrtStack *sp
 *                const mxArray *u
 *                const emlrtMsgIdentifier *parentId
 * Return Type  : real_T
 */
static real_T r_emlrt_marshallIn(const emlrtStack *sp, const mxArray *u,
                                 const emlrtMsgIdentifier *parentId)
{
  real_T y;
  y = bc_emlrt_marshallIn(sp, emlrtAlias(u), parentId);
  emlrtDestroyArray(&u);
  return y;
}

/*
 * Arguments    : const emlrtStack *sp
 *                const mxArray *nullptr
 *                const char_T *identifier
 *                int32_T *y_size
 * Return Type  : real_T *
 */
static real_T *rb_emlrt_marshallIn(const emlrtStack *sp, const mxArray *nullptr,
                                   const char_T *identifier, int32_T *y_size)
{
  emlrtMsgIdentifier thisId;
  real_T *y_data;
  int32_T i;
  thisId.fIdentifier = (const char_T *)identifier;
  thisId.fParent = NULL;
  thisId.bParentIsCell = false;
  y_data = sb_emlrt_marshallIn(sp, emlrtAlias(nullptr), &thisId, &i);
  *y_size = i;
  emlrtDestroyArray(&nullptr);
  return y_data;
}

/*
 * Arguments    : const emlrtStack *sp
 *                const mxArray *u
 *                const emlrtMsgIdentifier *parentId
 *                struct2_T *y
 * Return Type  : void
 */
static void s_emlrt_marshallIn(const emlrtStack *sp, const mxArray *u,
                               const emlrtMsgIdentifier *parentId, struct2_T *y)
{
  static const int32_T dims = 0;
  static const char_T *fieldNames[16] = {
      "dryMass",     "landingProp", "m0",           "Lb",
      "R",           "nEngine",     "thrustPerEng", "Isp",
      "throttleMin", "throttleMax", "tvcMax",       "tvcRate",
      "flapMax",     "flapMin",     "flapTrim",     "flapRate"};
  emlrtMsgIdentifier thisId;
  thisId.fParent = parentId;
  thisId.bParentIsCell = false;
  emlrtCheckStructR2012b((emlrtConstCTX)sp, parentId, u, 16,
                         (const char_T **)&fieldNames[0], 0U,
                         (const void *)&dims);
  thisId.fIdentifier = "dryMass";
  y->dryMass = r_emlrt_marshallIn(
      sp,
      emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 0, "dryMass")),
      &thisId);
  thisId.fIdentifier = "landingProp";
  y->landingProp =
      r_emlrt_marshallIn(sp,
                         emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0,
                                                        1, "landingProp")),
                         &thisId);
  thisId.fIdentifier = "m0";
  y->m0 = r_emlrt_marshallIn(
      sp, emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 2, "m0")),
      &thisId);
  thisId.fIdentifier = "Lb";
  y->Lb = r_emlrt_marshallIn(
      sp, emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 3, "Lb")),
      &thisId);
  thisId.fIdentifier = "R";
  y->R = r_emlrt_marshallIn(
      sp, emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 4, "R")),
      &thisId);
  thisId.fIdentifier = "nEngine";
  y->nEngine = r_emlrt_marshallIn(
      sp,
      emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 5, "nEngine")),
      &thisId);
  thisId.fIdentifier = "thrustPerEng";
  y->thrustPerEng =
      r_emlrt_marshallIn(sp,
                         emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0,
                                                        6, "thrustPerEng")),
                         &thisId);
  thisId.fIdentifier = "Isp";
  y->Isp = r_emlrt_marshallIn(
      sp, emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 7, "Isp")),
      &thisId);
  thisId.fIdentifier = "throttleMin";
  y->throttleMin =
      r_emlrt_marshallIn(sp,
                         emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0,
                                                        8, "throttleMin")),
                         &thisId);
  thisId.fIdentifier = "throttleMax";
  y->throttleMax =
      r_emlrt_marshallIn(sp,
                         emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0,
                                                        9, "throttleMax")),
                         &thisId);
  thisId.fIdentifier = "tvcMax";
  y->tvcMax = r_emlrt_marshallIn(
      sp,
      emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 10, "tvcMax")),
      &thisId);
  thisId.fIdentifier = "tvcRate";
  y->tvcRate = r_emlrt_marshallIn(
      sp,
      emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 11, "tvcRate")),
      &thisId);
  thisId.fIdentifier = "flapMax";
  y->flapMax = r_emlrt_marshallIn(
      sp,
      emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 12, "flapMax")),
      &thisId);
  thisId.fIdentifier = "flapMin";
  y->flapMin = r_emlrt_marshallIn(
      sp,
      emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 13, "flapMin")),
      &thisId);
  thisId.fIdentifier = "flapTrim";
  y->flapTrim = r_emlrt_marshallIn(
      sp,
      emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 14, "flapTrim")),
      &thisId);
  thisId.fIdentifier = "flapRate";
  y->flapRate = r_emlrt_marshallIn(
      sp,
      emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 15, "flapRate")),
      &thisId);
  emlrtDestroyArray(&u);
}

/*
 * Arguments    : const emlrtStack *sp
 *                const mxArray *u
 *                const emlrtMsgIdentifier *parentId
 *                int32_T *y_size
 * Return Type  : real_T *
 */
static real_T *sb_emlrt_marshallIn(const emlrtStack *sp, const mxArray *u,
                                   const emlrtMsgIdentifier *parentId,
                                   int32_T *y_size)
{
  real_T *y_data;
  int32_T i;
  y_data = pc_emlrt_marshallIn(sp, emlrtAlias(u), parentId, &i);
  *y_size = i;
  emlrtDestroyArray(&u);
  return y_data;
}

/*
 * Arguments    : const emlrtStack *sp
 *                const mxArray *u
 *                const emlrtMsgIdentifier *parentId
 *                real_T y[9]
 * Return Type  : void
 */
static void t_emlrt_marshallIn(const emlrtStack *sp, const mxArray *u,
                               const emlrtMsgIdentifier *parentId, real_T y[9])
{
  cc_emlrt_marshallIn(sp, emlrtAlias(u), parentId, y);
  emlrtDestroyArray(&u);
}

/*
 * Arguments    : const emlrtStack *sp
 *                const mxArray *src
 *                const emlrtMsgIdentifier *msgId
 * Return Type  : real_T (*)[14]
 */
static real_T (*tb_emlrt_marshallIn(const emlrtStack *sp, const mxArray *src,
                                    const emlrtMsgIdentifier *msgId))[14]
{
  static const int32_T dims = 14;
  real_T(*ret)[14];
  int32_T i;
  boolean_T b = false;
  emlrtCheckVsBuiltInR2012b((emlrtConstCTX)sp, msgId, src, "double", false, 1U,
                            (const void *)&dims, &b, &i);
  ret = (real_T(*)[14])emlrtMxGetData(src);
  emlrtDestroyArray(&src);
  return ret;
}

/*
 * Arguments    : const emlrtStack *sp
 *                const mxArray *u
 *                const emlrtMsgIdentifier *parentId
 *                real_T y[3]
 * Return Type  : void
 */
static void u_emlrt_marshallIn(const emlrtStack *sp, const mxArray *u,
                               const emlrtMsgIdentifier *parentId, real_T y[3])
{
  dc_emlrt_marshallIn(sp, emlrtAlias(u), parentId, y);
  emlrtDestroyArray(&u);
}

/*
 * Arguments    : const emlrtStack *sp
 *                const mxArray *src
 *                const emlrtMsgIdentifier *msgId
 * Return Type  : real_T (*)[12]
 */
static real_T (*ub_emlrt_marshallIn(const emlrtStack *sp, const mxArray *src,
                                    const emlrtMsgIdentifier *msgId))[12]
{
  static const int32_T dims = 12;
  real_T(*ret)[12];
  int32_T i;
  boolean_T b = false;
  emlrtCheckVsBuiltInR2012b((emlrtConstCTX)sp, msgId, src, "double", false, 1U,
                            (const void *)&dims, &b, &i);
  ret = (real_T(*)[12])emlrtMxGetData(src);
  emlrtDestroyArray(&src);
  return ret;
}

/*
 * Arguments    : const emlrtStack *sp
 *                const mxArray *u
 *                const emlrtMsgIdentifier *parentId
 *                real_T y[12]
 * Return Type  : void
 */
static void v_emlrt_marshallIn(const emlrtStack *sp, const mxArray *u,
                               const emlrtMsgIdentifier *parentId, real_T y[12])
{
  ec_emlrt_marshallIn(sp, emlrtAlias(u), parentId, y);
  emlrtDestroyArray(&u);
}

/*
 * Arguments    : const emlrtStack *sp
 *                const mxArray *src
 *                const emlrtMsgIdentifier *msgId
 *                int32_T ret_size[2]
 * Return Type  : real_T *
 */
static real_T *vb_emlrt_marshallIn(const emlrtStack *sp, const mxArray *src,
                                   const emlrtMsgIdentifier *msgId,
                                   int32_T ret_size[2])
{
  static const int32_T dims[2] = {14, 201};
  real_T *ret_data;
  int32_T iv[2];
  boolean_T bv[2] = {false, true};
  emlrtCheckVsBuiltInR2012b((emlrtConstCTX)sp, msgId, src, "double", false, 2U,
                            (const void *)&dims[0], &bv[0], &iv[0]);
  ret_size[0] = iv[0];
  ret_size[1] = iv[1];
  ret_data = (real_T *)emlrtMxGetData(src);
  emlrtDestroyArray(&src);
  return ret_data;
}

/*
 * Arguments    : const emlrtStack *sp
 *                const mxArray *u
 *                const emlrtMsgIdentifier *parentId
 *                real_T y[8]
 * Return Type  : void
 */
static void w_emlrt_marshallIn(const emlrtStack *sp, const mxArray *u,
                               const emlrtMsgIdentifier *parentId, real_T y[8])
{
  fc_emlrt_marshallIn(sp, emlrtAlias(u), parentId, y);
  emlrtDestroyArray(&u);
}

/*
 * Arguments    : const emlrtStack *sp
 *                const mxArray *src
 *                const emlrtMsgIdentifier *msgId
 *                int32_T ret_size[2]
 * Return Type  : real_T *
 */
static real_T *wb_emlrt_marshallIn(const emlrtStack *sp, const mxArray *src,
                                   const emlrtMsgIdentifier *msgId,
                                   int32_T ret_size[2])
{
  static const int32_T dims[2] = {7, 200};
  real_T *ret_data;
  int32_T iv[2];
  boolean_T bv[2] = {false, true};
  emlrtCheckVsBuiltInR2012b((emlrtConstCTX)sp, msgId, src, "double", false, 2U,
                            (const void *)&dims[0], &bv[0], &iv[0]);
  ret_size[0] = iv[0];
  ret_size[1] = iv[1];
  ret_data = (real_T *)emlrtMxGetData(src);
  emlrtDestroyArray(&src);
  return ret_data;
}

/*
 * Arguments    : const emlrtStack *sp
 *                const mxArray *nullptr
 *                const char_T *identifier
 *                struct3_T *y
 * Return Type  : void
 */
static void x_emlrt_marshallIn(const emlrtStack *sp, const mxArray *nullptr,
                               const char_T *identifier, struct3_T *y)
{
  emlrtMsgIdentifier thisId;
  thisId.fIdentifier = (const char_T *)identifier;
  thisId.fParent = NULL;
  thisId.bParentIsCell = false;
  y_emlrt_marshallIn(sp, emlrtAlias(nullptr), &thisId, y);
  emlrtDestroyArray(&nullptr);
}

/*
 * Arguments    : const emlrtStack *sp
 *                const mxArray *src
 *                const emlrtMsgIdentifier *msgId
 *                int32_T ret_size[2]
 * Return Type  : real_T *
 */
static real_T *xb_emlrt_marshallIn(const emlrtStack *sp, const mxArray *src,
                                   const emlrtMsgIdentifier *msgId,
                                   int32_T ret_size[2])
{
  static const int32_T dims[2] = {1, 200};
  real_T *ret_data;
  int32_T iv[2];
  boolean_T bv[2] = {false, true};
  emlrtCheckVsBuiltInR2012b((emlrtConstCTX)sp, msgId, src, "double", false, 2U,
                            (const void *)&dims[0], &bv[0], &iv[0]);
  ret_size[0] = iv[0];
  ret_size[1] = iv[1];
  ret_data = (real_T *)emlrtMxGetData(src);
  emlrtDestroyArray(&src);
  return ret_data;
}

/*
 * Arguments    : const emlrtStack *sp
 *                const mxArray *u
 *                const emlrtMsgIdentifier *parentId
 *                struct3_T *y
 * Return Type  : void
 */
static void y_emlrt_marshallIn(const emlrtStack *sp, const mxArray *u,
                               const emlrtMsgIdentifier *parentId, struct3_T *y)
{
  static const int32_T dims = 0;
  static const char_T *fieldNames[38] = {
      "tolPos",      "tolVel",      "tolQuat",  "tolRate",    "tolMass",
      "tolThr",      "tolFlap",     "tolSig",   "wFuel",      "lamVC",
      "lamTerm",     "lamGlide",    "reg",      "trX",        "trU",
      "trSig",       "sigMin",      "sigMax",   "hMargin",    "phaseTight",
      "wMaxFlip",    "wMaxTight",   "tiltMax",  "glideSlope", "nCone",
      "coneHalf",    "coneShrink",  "lcTol",    "bellyHold",  "qBelly",
      "softGlide",   "monoDescent", "useDrBox", "drBox",      "crMax",
      "thrMaxTight", "wTilt",       "rateLim"};
  emlrtMsgIdentifier thisId;
  thisId.fParent = parentId;
  thisId.bParentIsCell = false;
  emlrtCheckStructR2012b((emlrtConstCTX)sp, parentId, u, 38,
                         (const char_T **)&fieldNames[0], 0U,
                         (const void *)&dims);
  thisId.fIdentifier = "tolPos";
  y->tolPos = r_emlrt_marshallIn(
      sp, emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 0, "tolPos")),
      &thisId);
  thisId.fIdentifier = "tolVel";
  y->tolVel = r_emlrt_marshallIn(
      sp, emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 1, "tolVel")),
      &thisId);
  thisId.fIdentifier = "tolQuat";
  y->tolQuat = r_emlrt_marshallIn(
      sp,
      emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 2, "tolQuat")),
      &thisId);
  thisId.fIdentifier = "tolRate";
  y->tolRate = r_emlrt_marshallIn(
      sp,
      emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 3, "tolRate")),
      &thisId);
  thisId.fIdentifier = "tolMass";
  y->tolMass = r_emlrt_marshallIn(
      sp,
      emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 4, "tolMass")),
      &thisId);
  thisId.fIdentifier = "tolThr";
  y->tolThr = r_emlrt_marshallIn(
      sp, emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 5, "tolThr")),
      &thisId);
  thisId.fIdentifier = "tolFlap";
  y->tolFlap = r_emlrt_marshallIn(
      sp,
      emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 6, "tolFlap")),
      &thisId);
  thisId.fIdentifier = "tolSig";
  y->tolSig = r_emlrt_marshallIn(
      sp, emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 7, "tolSig")),
      &thisId);
  thisId.fIdentifier = "wFuel";
  y->wFuel = r_emlrt_marshallIn(
      sp, emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 8, "wFuel")),
      &thisId);
  thisId.fIdentifier = "lamVC";
  y->lamVC = r_emlrt_marshallIn(
      sp, emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 9, "lamVC")),
      &thisId);
  thisId.fIdentifier = "lamTerm";
  y->lamTerm = r_emlrt_marshallIn(
      sp,
      emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 10, "lamTerm")),
      &thisId);
  thisId.fIdentifier = "lamGlide";
  y->lamGlide = r_emlrt_marshallIn(
      sp,
      emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 11, "lamGlide")),
      &thisId);
  thisId.fIdentifier = "reg";
  y->reg = r_emlrt_marshallIn(
      sp, emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 12, "reg")),
      &thisId);
  thisId.fIdentifier = "trX";
  y->trX = r_emlrt_marshallIn(
      sp, emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 13, "trX")),
      &thisId);
  thisId.fIdentifier = "trU";
  y->trU = r_emlrt_marshallIn(
      sp, emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 14, "trU")),
      &thisId);
  thisId.fIdentifier = "trSig";
  y->trSig = r_emlrt_marshallIn(
      sp, emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 15, "trSig")),
      &thisId);
  thisId.fIdentifier = "sigMin";
  ab_emlrt_marshallIn(
      sp,
      emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 16, "sigMin")),
      &thisId, y->sigMin);
  thisId.fIdentifier = "sigMax";
  ab_emlrt_marshallIn(
      sp,
      emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 17, "sigMax")),
      &thisId, y->sigMax);
  thisId.fIdentifier = "hMargin";
  y->hMargin = r_emlrt_marshallIn(
      sp,
      emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 18, "hMargin")),
      &thisId);
  thisId.fIdentifier = "phaseTight";
  y->phaseTight =
      r_emlrt_marshallIn(sp,
                         emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0,
                                                        19, "phaseTight")),
                         &thisId);
  thisId.fIdentifier = "wMaxFlip";
  y->wMaxFlip = r_emlrt_marshallIn(
      sp,
      emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 20, "wMaxFlip")),
      &thisId);
  thisId.fIdentifier = "wMaxTight";
  y->wMaxTight = r_emlrt_marshallIn(
      sp,
      emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 21, "wMaxTight")),
      &thisId);
  thisId.fIdentifier = "tiltMax";
  y->tiltMax = r_emlrt_marshallIn(
      sp,
      emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 22, "tiltMax")),
      &thisId);
  thisId.fIdentifier = "glideSlope";
  y->glideSlope =
      r_emlrt_marshallIn(sp,
                         emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0,
                                                        23, "glideSlope")),
                         &thisId);
  thisId.fIdentifier = "nCone";
  y->nCone = r_emlrt_marshallIn(
      sp, emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 24, "nCone")),
      &thisId);
  thisId.fIdentifier = "coneHalf";
  y->coneHalf = r_emlrt_marshallIn(
      sp,
      emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 25, "coneHalf")),
      &thisId);
  thisId.fIdentifier = "coneShrink";
  y->coneShrink =
      r_emlrt_marshallIn(sp,
                         emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0,
                                                        26, "coneShrink")),
                         &thisId);
  thisId.fIdentifier = "lcTol";
  y->lcTol = r_emlrt_marshallIn(
      sp, emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 27, "lcTol")),
      &thisId);
  thisId.fIdentifier = "bellyHold";
  y->bellyHold = r_emlrt_marshallIn(
      sp,
      emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 28, "bellyHold")),
      &thisId);
  thisId.fIdentifier = "qBelly";
  bb_emlrt_marshallIn(
      sp,
      emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 29, "qBelly")),
      &thisId, y->qBelly);
  thisId.fIdentifier = "softGlide";
  y->softGlide = r_emlrt_marshallIn(
      sp,
      emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 30, "softGlide")),
      &thisId);
  thisId.fIdentifier = "monoDescent";
  y->monoDescent =
      r_emlrt_marshallIn(sp,
                         emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0,
                                                        31, "monoDescent")),
                         &thisId);
  thisId.fIdentifier = "useDrBox";
  y->useDrBox = r_emlrt_marshallIn(
      sp,
      emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 32, "useDrBox")),
      &thisId);
  thisId.fIdentifier = "drBox";
  cb_emlrt_marshallIn(
      sp, emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 33, "drBox")),
      &thisId, y->drBox);
  thisId.fIdentifier = "crMax";
  y->crMax = r_emlrt_marshallIn(
      sp, emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 34, "crMax")),
      &thisId);
  thisId.fIdentifier = "thrMaxTight";
  y->thrMaxTight =
      r_emlrt_marshallIn(sp,
                         emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0,
                                                        35, "thrMaxTight")),
                         &thisId);
  thisId.fIdentifier = "wTilt";
  y->wTilt = r_emlrt_marshallIn(
      sp, emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 36, "wTilt")),
      &thisId);
  thisId.fIdentifier = "rateLim";
  y->rateLim = r_emlrt_marshallIn(
      sp,
      emlrtAlias(emlrtGetFieldR2017b((emlrtConstCTX)sp, u, 0, 37, "rateLim")),
      &thisId);
  emlrtDestroyArray(&u);
}

/*
 * Arguments    : const emlrtStack *sp
 *                const mxArray *src
 *                const emlrtMsgIdentifier *msgId
 *                int32_T ret_size[2]
 * Return Type  : real_T *
 */
static real_T *yb_emlrt_marshallIn(const emlrtStack *sp, const mxArray *src,
                                   const emlrtMsgIdentifier *msgId,
                                   int32_T ret_size[2])
{
  static const int32_T dims[2] = {1, 8};
  real_T *ret_data;
  int32_T iv[2];
  boolean_T bv[2] = {false, true};
  emlrtCheckVsBuiltInR2012b((emlrtConstCTX)sp, msgId, src, "double", false, 2U,
                            (const void *)&dims[0], &bv[0], &iv[0]);
  ret_size[0] = iv[0];
  ret_size[1] = iv[1];
  ret_data = (real_T *)emlrtMxGetData(src);
  emlrtDestroyArray(&src);
  return ret_data;
}

/*
 * Arguments    : void
 * Return Type  : void
 */
void gncCore_lib_atexit(void)
{
  emlrtStack st = {
      NULL, /* site */
      NULL, /* tls */
      NULL  /* prev */
  };
  mexFunctionCreateRootTLS();
  st.tls = emlrtRootTLSGlobal;
  emlrtPushHeapReferenceStackR2021a(
      &st, false, NULL, (void *)&emlrtExitTimeCleanupDtorFcn, NULL, NULL, NULL);
  emlrtEnterRtStackR2012b(&st);
  emlrtDestroyRootTLS(&emlrtRootTLSGlobal);
  gncCore_lib_xil_terminate();
  gncCore_lib_xil_shutdown();
  emlrtExitTimeCleanup(&emlrtContextGlobal);
}

/*
 * Arguments    : void
 * Return Type  : void
 */
void gncCore_lib_initialize(void)
{
  emlrtStack st = {
      NULL, /* site */
      NULL, /* tls */
      NULL  /* prev */
  };
  mexFunctionCreateRootTLS();
  st.tls = emlrtRootTLSGlobal;
  emlrtClearAllocCountR2012b(&st, false, 0U, NULL);
  emlrtEnterRtStackR2012b(&st);
  emlrtFirstTimeR2012b(emlrtRootTLSGlobal);
}

/*
 * Arguments    : void
 * Return Type  : void
 */
void gncCore_lib_terminate(void)
{
  emlrtDestroyRootTLS(&emlrtRootTLSGlobal);
}

/*
 * Arguments    : const mxArray * const prhs[14]
 *                int32_T nlhs
 *                const mxArray *plhs[9]
 * Return Type  : void
 */
void scpk_planIterEmb_api(const mxArray *const prhs[14], int32_T nlhs,
                          const mxArray *plhs[9])
{
  emlrtStack b_st = {
      NULL, /* site */
      NULL, /* tls */
      NULL  /* prev */
  };
  emxArray_real_T *zOut;
  emxArray_real_T *zWarm;
  struct0_T cfg;
  struct3_T pp;
  struct4_T qp;
  real_T(*xl_data)[2814];
  real_T(*xs_data)[2814];
  real_T(*ul_data)[1400];
  real_T(*us_data)[1400];
  real_T(*tiltN_data)[201];
  real_T(*dtv_data)[200];
  real_T(*eng_data)[200];
  real_T(*gl_data)[200];
  real_T(*gs_data)[200];
  real_T(*phase_data)[200];
  real_T(*x0nd)[14];
  real_T(*xT)[12];
  real_T(*sigl_data)[8];
  real_T(*ss_data)[8];
  real_T nu;
  real_T step;
  int32_T dtv_size[2];
  int32_T eng_size[2];
  int32_T gl_size[2];
  int32_T gs_size[2];
  int32_T phase_size[2];
  int32_T sigl_size[2];
  int32_T ss_size[2];
  int32_T tiltN_size[2];
  int32_T ul_size[2];
  int32_T us_size[2];
  int32_T xl_size[2];
  int32_T xs_size[2];
  int32_T iters;
  int32_T st;
  b_st.tls = emlrtRootTLSGlobal;
  xs_data = (real_T(*)[2814])mxMalloc(sizeof(real_T[2814]));
  us_data = (real_T(*)[1400])mxMalloc(sizeof(real_T[1400]));
  gs_data = (real_T(*)[200])mxMalloc(sizeof(real_T[200]));
  ss_data = (real_T(*)[8])mxMalloc(sizeof(real_T[8]));
  emlrtHeapReferenceStackEnterFcnR2012b(&b_st);
  /* Marshall function inputs */
  x0nd = emlrt_marshallIn(&b_st, emlrtAlias(prhs[0]), "x0nd");
  xT = c_emlrt_marshallIn(&b_st, emlrtAlias(prhs[1]), "xT");
  *(real_T **)&xl_data =
      e_emlrt_marshallIn(&b_st, emlrtAlias(prhs[2]), "xl", xl_size);
  *(real_T **)&ul_data =
      g_emlrt_marshallIn(&b_st, emlrtAlias(prhs[3]), "ul", ul_size);
  *(real_T **)&gl_data =
      i_emlrt_marshallIn(&b_st, emlrtAlias(prhs[4]), "gl", gl_size);
  *(real_T **)&sigl_data =
      k_emlrt_marshallIn(&b_st, emlrtAlias(prhs[5]), "sigl", sigl_size);
  *(real_T **)&phase_data =
      i_emlrt_marshallIn(&b_st, emlrtAlias(prhs[6]), "phase", phase_size);
  *(real_T **)&eng_data =
      i_emlrt_marshallIn(&b_st, emlrtAlias(prhs[7]), "eng", eng_size);
  *(real_T **)&dtv_data =
      i_emlrt_marshallIn(&b_st, emlrtAlias(prhs[8]), "dtv", dtv_size);
  *(real_T **)&tiltN_data =
      m_emlrt_marshallIn(&b_st, emlrtAlias(prhs[9]), "tiltN", tiltN_size);
  o_emlrt_marshallIn(&b_st, emlrtAliasP(prhs[10]), "cfg", &cfg);
  x_emlrt_marshallIn(&b_st, emlrtAliasP(prhs[11]), "pp", &pp);
  db_emlrt_marshallIn(&b_st, emlrtAliasP(prhs[12]), "qp", &qp);
  emxInit_real_T(&b_st, &zWarm);
  zWarm->canFreeData = false;
  fb_emlrt_marshallIn(&b_st, emlrtAlias(prhs[13]), "zWarm", zWarm);
  /* Invoke the target function */
  emxInit_real_T(&b_st, &zOut);
  scpk_planIterEmb(*x0nd, *xT, *xl_data, xl_size, *ul_data, ul_size, *gl_data,
                   gl_size, *sigl_data, sigl_size, *phase_data, phase_size,
                   *eng_data, eng_size, *dtv_data, dtv_size, *tiltN_data,
                   tiltN_size, &cfg, &pp, &qp, zWarm, *xs_data, xs_size,
                   *us_data, us_size, *gs_data, gs_size, *ss_data, ss_size, &st,
                   &iters, &nu, &step, zOut);
  emxFree_real_T(&b_st, &zWarm);
  /* Marshall function outputs */
  plhs[0] = emlrt_marshallOut(*xs_data, xs_size);
  if (nlhs > 1) {
    plhs[1] = emlrt_marshallOut(*us_data, us_size);
  }
  if (nlhs > 2) {
    plhs[2] = emlrt_marshallOut(*gs_data, gs_size);
  }
  if (nlhs > 3) {
    plhs[3] = emlrt_marshallOut(*ss_data, ss_size);
  }
  if (nlhs > 4) {
    plhs[4] = b_emlrt_marshallOut(st);
  }
  if (nlhs > 5) {
    plhs[5] = b_emlrt_marshallOut(iters);
  }
  if (nlhs > 6) {
    plhs[6] = c_emlrt_marshallOut(nu);
  }
  if (nlhs > 7) {
    plhs[7] = c_emlrt_marshallOut(step);
  }
  if (nlhs > 8) {
    zOut->canFreeData = false;
    plhs[8] = d_emlrt_marshallOut(zOut);
  }
  emxFree_real_T(&b_st, &zOut);
  emlrtHeapReferenceStackLeaveFcnR2012b(&b_st);
}

/*
 * Arguments    : const mxArray * const prhs[7]
 *                int32_T nlhs
 *                const mxArray *plhs[5]
 * Return Type  : void
 */
void scpk_trackStepEmb_api(const mxArray *const prhs[7], int32_T nlhs,
                           const mxArray *plhs[5])
{
  emlrtStack b_st = {
      NULL, /* site */
      NULL, /* tls */
      NULL  /* prev */
  };
  struct0_T cfg;
  struct5_T tp;
  real_T(*zWarm_data)[1300];
  real_T(*zOut_data)[1260];
  real_T(*xr_data)[854];
  real_T(*ur_data)[420];
  real_T(*engk_data)[60];
  real_T(*xcPhys)[14];
  real_T(*u0)[7];
  real_T(*qCmd)[4];
  int32_T engk_size[2];
  int32_T ur_size[2];
  int32_T xr_size[2];
  int32_T iters;
  int32_T st;
  int32_T zOut_size;
  int32_T zWarm_size;
  b_st.tls = emlrtRootTLSGlobal;
  u0 = (real_T(*)[7])mxMalloc(sizeof(real_T[7]));
  zOut_data = (real_T(*)[1260])mxMalloc(sizeof(real_T[1260]));
  qCmd = (real_T(*)[4])mxMalloc(sizeof(real_T[4]));
  /* Marshall function inputs */
  xcPhys = emlrt_marshallIn(&b_st, emlrtAlias(prhs[0]), "xcPhys");
  *(real_T **)&xr_data =
      hb_emlrt_marshallIn(&b_st, emlrtAlias(prhs[1]), "xr", xr_size);
  *(real_T **)&ur_data =
      jb_emlrt_marshallIn(&b_st, emlrtAlias(prhs[2]), "ur", ur_size);
  *(real_T **)&engk_data =
      lb_emlrt_marshallIn(&b_st, emlrtAlias(prhs[3]), "engk", engk_size);
  o_emlrt_marshallIn(&b_st, emlrtAliasP(prhs[4]), "cfg", &cfg);
  nb_emlrt_marshallIn(&b_st, emlrtAliasP(prhs[5]), "tp", &tp);
  *(real_T **)&zWarm_data =
      rb_emlrt_marshallIn(&b_st, emlrtAlias(prhs[6]), "zWarm", &zWarm_size);
  /* Invoke the target function */
  scpk_trackStepEmb(*xcPhys, *xr_data, xr_size, *ur_data, ur_size, *engk_data,
                    engk_size, &cfg, &tp, *zWarm_data, &zWarm_size, *u0,
                    *zOut_data, &zOut_size, *qCmd, &st, &iters);
  /* Marshall function outputs */
  plhs[0] = e_emlrt_marshallOut(*u0);
  if (nlhs > 1) {
    plhs[1] = f_emlrt_marshallOut(*zOut_data, &zOut_size);
  }
  if (nlhs > 2) {
    plhs[2] = g_emlrt_marshallOut(*qCmd);
  }
  if (nlhs > 3) {
    plhs[3] = b_emlrt_marshallOut(st);
  }
  if (nlhs > 4) {
    plhs[4] = b_emlrt_marshallOut(iters);
  }
}

/*
 * File trailer for _coder_gncCore_lib_api.c
 *
 * [EOF]
 */
