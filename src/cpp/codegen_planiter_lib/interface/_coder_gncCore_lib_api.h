/*
 * File: _coder_gncCore_lib_api.h
 *
 * MATLAB Coder version            : 24.2
 * C/C++ source code generated on  : 2026/08/28 22:18:33
 */

#ifndef _CODER_GNCCORE_LIB_API_H
#define _CODER_GNCCORE_LIB_API_H

/* Include Files */
#include "emlrt.h"
#include "mex.h"
#include "tmwtypes.h"
#include <string.h>

/* Type Definitions */
#ifndef typedef_struct1_T
#define typedef_struct1_T
typedef struct {
  real_T L;
  real_T T;
  real_T V;
  real_T A;
} struct1_T;
#endif /* typedef_struct1_T */

#ifndef typedef_struct2_T
#define typedef_struct2_T
typedef struct {
  real_T dryMass;
  real_T landingProp;
  real_T m0;
  real_T Lb;
  real_T R;
  real_T nEngine;
  real_T thrustPerEng;
  real_T Isp;
  real_T throttleMin;
  real_T throttleMax;
  real_T tvcMax;
  real_T tvcRate;
  real_T flapMax;
  real_T flapMin;
  real_T flapTrim;
  real_T flapRate;
} struct2_T;
#endif /* typedef_struct2_T */

#ifndef typedef_struct4_T
#define typedef_struct4_T
typedef struct {
  real_T maxIter;
  real_T fixedIter;
  real_T tolPri;
  real_T tolDua;
  real_T omega;
  real_T rho;
  real_T checkEvery;
  real_T powerIter;
  real_T certAfter;
  real_T certTol;
  real_T certEps;
} struct4_T;
#endif /* typedef_struct4_T */

#ifndef typedef_struct5_T
#define typedef_struct5_T
typedef struct {
  real_T dtau;
  real_T Dx[14];
  real_T Du[7];
  real_T wx[14];
  real_T rCtrl;
  real_T wTerm;
  real_T reg;
  real_T maxIter;
  real_T fixedIter;
  real_T tolPri;
  real_T tolDua;
  real_T omega;
  real_T rho;
  real_T checkEvery;
  real_T powerIter;
} struct5_T;
#endif /* typedef_struct5_T */

#ifndef typedef_struct0_T
#define typedef_struct0_T
typedef struct {
  struct1_T sc;
  struct2_T veh;
  real_T m0;
  real_T Fs;
  real_T J[9];
  real_T Jinv[9];
  real_T Jphys[9];
  real_T Tmin1;
  real_T Tmax1;
  real_T nEng;
  real_T Tmin;
  real_T Tmax;
  real_T tanGim;
  real_T alpha;
  real_T rT[3];
  real_T gI[3];
  real_T cx;
  real_T cy;
  real_T cz;
  real_T LoverD;
  real_T cL;
  real_T rho;
  real_T aeroScale;
  real_T surfMode;
  real_T V2ref;
  real_T Bflap[12];
  real_T cFlapDrag;
  real_T jacStep;
  real_T vEps;
  real_T tEps;
  real_T mhatMin;
  real_T wMax;
  real_T hmin;
  real_T atmIsa;
  real_T hPad;
  real_T wOn;
  real_T wTabH[8];
  real_T wTabY[8];
  real_T wTabZ[8];
} struct0_T;
#endif /* typedef_struct0_T */

#ifndef typedef_struct3_T
#define typedef_struct3_T
typedef struct {
  real_T tolPos;
  real_T tolVel;
  real_T tolQuat;
  real_T tolRate;
  real_T tolMass;
  real_T tolThr;
  real_T tolFlap;
  real_T tolSig;
  real_T wFuel;
  real_T lamVC;
  real_T lamTerm;
  real_T lamGlide;
  real_T reg;
  real_T trX;
  real_T trU;
  real_T trSig;
  real_T sigMin[4];
  real_T sigMax[4];
  real_T hMargin;
  real_T phaseTight;
  real_T wMaxFlip;
  real_T wMaxTight;
  real_T tiltMax;
  real_T glideSlope;
  real_T nCone;
  real_T coneHalf;
  real_T coneShrink;
  real_T lcTol;
  real_T bellyHold;
  real_T qBelly[4];
  real_T softGlide;
  real_T monoDescent;
  real_T useDrBox;
  real_T drBox[2];
  real_T crMax;
  real_T thrMaxTight;
  real_T wTilt;
  real_T rateLim;
} struct3_T;
#endif /* typedef_struct3_T */

#ifndef struct_emxArray_real_T
#define struct_emxArray_real_T
struct emxArray_real_T {
  real_T *data;
  int32_T *size;
  int32_T allocatedSize;
  int32_T numDimensions;
  boolean_T canFreeData;
};
#endif /* struct_emxArray_real_T */
#ifndef typedef_emxArray_real_T
#define typedef_emxArray_real_T
typedef struct emxArray_real_T emxArray_real_T;
#endif /* typedef_emxArray_real_T */

/* Variable Declarations */
extern emlrtCTX emlrtRootTLSGlobal;
extern emlrtContext emlrtContextGlobal;

#ifdef __cplusplus
extern "C" {
#endif

/* Function Declarations */
void gncCore_lib_atexit(void);

void gncCore_lib_initialize(void);

void gncCore_lib_terminate(void);

void gncCore_lib_xil_shutdown(void);

void gncCore_lib_xil_terminate(void);

void scpk_planIterEmb(real_T x0nd[14], real_T xT[12], real_T xl_data[],
                      int32_T xl_size[2], real_T ul_data[], int32_T ul_size[2],
                      real_T gl_data[], int32_T gl_size[2], real_T sigl_data[],
                      int32_T sigl_size[2], real_T phase_data[],
                      int32_T phase_size[2], real_T eng_data[],
                      int32_T eng_size[2], real_T dtv_data[],
                      int32_T dtv_size[2], real_T tiltN_data[],
                      int32_T tiltN_size[2], struct0_T *cfg, struct3_T *pp,
                      struct4_T *qp, emxArray_real_T *zWarm, real_T xs_data[],
                      int32_T xs_size[2], real_T us_data[], int32_T us_size[2],
                      real_T gs_data[], int32_T gs_size[2], real_T ss_data[],
                      int32_T ss_size[2], int32_T *st, int32_T *iters,
                      real_T *nu, real_T *step, emxArray_real_T *zOut);

void scpk_planIterEmb_api(const mxArray *const prhs[14], int32_T nlhs,
                          const mxArray *plhs[9]);

void scpk_trackStepEmb(real_T xcPhys[14], real_T xr_data[], int32_T xr_size[2],
                       real_T ur_data[], int32_T ur_size[2], real_T engk_data[],
                       int32_T engk_size[2], struct0_T *cfg, struct5_T *tp,
                       real_T zWarm_data[], int32_T zWarm_size[1], real_T u0[7],
                       real_T zOut_data[], int32_T zOut_size[1], real_T qCmd[4],
                       int32_T *st, int32_T *iters);

void scpk_trackStepEmb_api(const mxArray *const prhs[7], int32_T nlhs,
                           const mxArray *plhs[5]);

#ifdef __cplusplus
}
#endif

#endif
/*
 * File trailer for _coder_gncCore_lib_api.h
 *
 * [EOF]
 */
