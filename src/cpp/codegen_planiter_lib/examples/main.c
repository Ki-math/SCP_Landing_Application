/*
 * File: main.c
 *
 * MATLAB Coder version            : 24.2
 * C/C++ source code generated on  : 2026/08/29 11:14:48
 */

/*************************************************************************/
/* This automatically generated example C main file shows how to call    */
/* entry-point functions that MATLAB Coder generated. You must customize */
/* this file for your application. Do not modify this file directly.     */
/* Instead, make a copy of this file, modify it, and integrate it into   */
/* your development environment.                                         */
/*                                                                       */
/* This file initializes entry-point function arguments to a default     */
/* size and value before calling the entry-point functions. It does      */
/* not store or use any values returned from the entry-point functions.  */
/* If necessary, it does pre-allocate memory for returned values.        */
/* You can use this file as a starting point for a main function that    */
/* you can deploy in your application.                                   */
/*                                                                       */
/* After you copy the file, and before you deploy it, you must make the  */
/* following changes:                                                    */
/* * For variable-size function arguments, change the example sizes to   */
/* the sizes that your application requires.                             */
/* * Change the example values of function arguments to the values that  */
/* your application requires.                                            */
/* * If the entry-point functions return values, store these values or   */
/* otherwise use them as required by your application.                   */
/*                                                                       */
/*************************************************************************/

/* Include Files */
#include "main.h"
#include "gncCore_lib_emxAPI.h"
#include "gncCore_lib_terminate.h"
#include "gncCore_lib_types.h"
#include "rt_nonfinite.h"
#include "scpk_planIterEmb.h"
#include "scpk_trackStepEmb.h"
#include <string.h>

/* Function Declarations */
static void argInit_12x1_real_T(double result[12]);

static void argInit_14x1_real_T(double result[14]);

static void argInit_14xd201_real_T(double result_data[], int result_size[2]);

static void argInit_1x2_real_T(double result[2]);

static void argInit_1x4_real_T(double result[4]);

static void argInit_1x8_real_T(double result[8]);

static void argInit_1xd200_real_T(double result_data[], int result_size[2]);

static void argInit_3x1_real_T(double result[3]);

static void argInit_3x3_real_T(double result[9]);

static void argInit_7x1_real_T(double result[7]);

static void argInit_7xd200_real_T(double result_data[], int result_size[2]);

static emxArray_real_T *argInit_d12000x1_real_T(void);

static int argInit_d1300x1_real_T(double result_data[]);

static double argInit_real_T(void);

static void argInit_struct0_T(struct0_T *result);

static struct1_T argInit_struct1_T(void);

static void argInit_struct2_T(struct2_T *result);

static void argInit_struct3_T(struct3_T *result);

static void argInit_struct4_T(struct4_T *result);

static void argInit_struct5_T(struct5_T *result);

/* Function Definitions */
/*
 * Arguments    : double result[12]
 * Return Type  : void
 */
static void argInit_12x1_real_T(double result[12])
{
  int idx0;
  /* Loop over the array to initialize each element. */
  for (idx0 = 0; idx0 < 12; idx0++) {
    /* Set the value of the array element.
Change this value to the value that the application requires. */
    result[idx0] = argInit_real_T();
  }
}

/*
 * Arguments    : double result[14]
 * Return Type  : void
 */
static void argInit_14x1_real_T(double result[14])
{
  int idx0;
  /* Loop over the array to initialize each element. */
  for (idx0 = 0; idx0 < 14; idx0++) {
    /* Set the value of the array element.
Change this value to the value that the application requires. */
    result[idx0] = argInit_real_T();
  }
}

/*
 * Arguments    : double result_data[]
 *                int result_size[2]
 * Return Type  : void
 */
static void argInit_14xd201_real_T(double result_data[], int result_size[2])
{
  int i;
  /* Set the size of the array.
Change this size to the value that the application requires. */
  result_size[0] = 14;
  result_size[1] = 2;
  /* Loop over the array to initialize each element. */
  for (i = 0; i < 28; i++) {
    /* Set the value of the array element.
Change this value to the value that the application requires. */
    result_data[i] = argInit_real_T();
  }
}

/*
 * Arguments    : double result[2]
 * Return Type  : void
 */
static void argInit_1x2_real_T(double result[2])
{
  int idx1;
  /* Loop over the array to initialize each element. */
  for (idx1 = 0; idx1 < 2; idx1++) {
    /* Set the value of the array element.
Change this value to the value that the application requires. */
    result[idx1] = argInit_real_T();
  }
}

/*
 * Arguments    : double result[4]
 * Return Type  : void
 */
static void argInit_1x4_real_T(double result[4])
{
  int idx1;
  /* Loop over the array to initialize each element. */
  for (idx1 = 0; idx1 < 4; idx1++) {
    /* Set the value of the array element.
Change this value to the value that the application requires. */
    result[idx1] = argInit_real_T();
  }
}

/*
 * Arguments    : double result[8]
 * Return Type  : void
 */
static void argInit_1x8_real_T(double result[8])
{
  int idx1;
  /* Loop over the array to initialize each element. */
  for (idx1 = 0; idx1 < 8; idx1++) {
    /* Set the value of the array element.
Change this value to the value that the application requires. */
    result[idx1] = argInit_real_T();
  }
}

/*
 * Arguments    : double result_data[]
 *                int result_size[2]
 * Return Type  : void
 */
static void argInit_1xd200_real_T(double result_data[], int result_size[2])
{
  int idx1;
  /* Set the size of the array.
Change this size to the value that the application requires. */
  result_size[0] = 1;
  result_size[1] = 2;
  /* Loop over the array to initialize each element. */
  for (idx1 = 0; idx1 < 2; idx1++) {
    /* Set the value of the array element.
Change this value to the value that the application requires. */
    result_data[idx1] = argInit_real_T();
  }
}

/*
 * Arguments    : double result[3]
 * Return Type  : void
 */
static void argInit_3x1_real_T(double result[3])
{
  int idx0;
  /* Loop over the array to initialize each element. */
  for (idx0 = 0; idx0 < 3; idx0++) {
    /* Set the value of the array element.
Change this value to the value that the application requires. */
    result[idx0] = argInit_real_T();
  }
}

/*
 * Arguments    : double result[9]
 * Return Type  : void
 */
static void argInit_3x3_real_T(double result[9])
{
  int i;
  /* Loop over the array to initialize each element. */
  for (i = 0; i < 9; i++) {
    /* Set the value of the array element.
Change this value to the value that the application requires. */
    result[i] = argInit_real_T();
  }
}

/*
 * Arguments    : double result[7]
 * Return Type  : void
 */
static void argInit_7x1_real_T(double result[7])
{
  int idx0;
  /* Loop over the array to initialize each element. */
  for (idx0 = 0; idx0 < 7; idx0++) {
    /* Set the value of the array element.
Change this value to the value that the application requires. */
    result[idx0] = argInit_real_T();
  }
}

/*
 * Arguments    : double result_data[]
 *                int result_size[2]
 * Return Type  : void
 */
static void argInit_7xd200_real_T(double result_data[], int result_size[2])
{
  int i;
  /* Set the size of the array.
Change this size to the value that the application requires. */
  result_size[0] = 7;
  result_size[1] = 2;
  /* Loop over the array to initialize each element. */
  for (i = 0; i < 14; i++) {
    /* Set the value of the array element.
Change this value to the value that the application requires. */
    result_data[i] = argInit_real_T();
  }
}

/*
 * Arguments    : void
 * Return Type  : emxArray_real_T *
 */
static emxArray_real_T *argInit_d12000x1_real_T(void)
{
  emxArray_real_T *result;
  double *result_data;
  int idx0 = 2;
  /* Set the size of the array.
Change this size to the value that the application requires. */
  result = emxCreateND_real_T(1, &idx0);
  result_data = result->data;
  /* Loop over the array to initialize each element. */
  for (idx0 = 0; idx0 < result->size[0U]; idx0++) {
    /* Set the value of the array element.
Change this value to the value that the application requires. */
    result_data[idx0] = argInit_real_T();
  }
  return result;
}

/*
 * Arguments    : double result_data[]
 * Return Type  : int
 */
static int argInit_d1300x1_real_T(double result_data[])
{
  int idx0;
  int result_size;
  /* Set the size of the array.
Change this size to the value that the application requires. */
  result_size = 2;
  /* Loop over the array to initialize each element. */
  for (idx0 = 0; idx0 < 2; idx0++) {
    /* Set the value of the array element.
Change this value to the value that the application requires. */
    result_data[idx0] = argInit_real_T();
  }
  return result_size;
}

/*
 * Arguments    : void
 * Return Type  : double
 */
static double argInit_real_T(void)
{
  return 0.0;
}

/*
 * Arguments    : struct0_T *result
 * Return Type  : void
 */
static void argInit_struct0_T(struct0_T *result)
{
  double result_tmp;
  int i;
  /* Set the value of each structure field.
Change this value to the value that the application requires. */
  result_tmp = argInit_real_T();
  argInit_3x3_real_T(result->J);
  argInit_3x1_real_T(result->rT);
  argInit_1x8_real_T(result->wTabH);
  result->sc = argInit_struct1_T();
  argInit_struct2_T(&result->veh);
  result->m0 = result_tmp;
  result->Fs = result_tmp;
  result->Tmin1 = result_tmp;
  result->Tmax1 = result_tmp;
  result->nEng = result_tmp;
  result->Tmin = result_tmp;
  result->Tmax = result_tmp;
  result->tanGim = result_tmp;
  result->alpha = result_tmp;
  result->cx = result_tmp;
  result->cy = result_tmp;
  result->cz = result_tmp;
  result->LoverD = result_tmp;
  result->cL = result_tmp;
  result->rho = result_tmp;
  result->aeroScale = result_tmp;
  result->surfMode = result_tmp;
  result->V2ref = result_tmp;
  argInit_12x1_real_T(result->Bflap);
  result->cFlapDrag = result_tmp;
  result->jacStep = result_tmp;
  result->vEps = result_tmp;
  result->tEps = result_tmp;
  result->mhatMin = result_tmp;
  result->wMax = result_tmp;
  result->hmin = result_tmp;
  result->atmIsa = result_tmp;
  result->hPad = result_tmp;
  result->wOn = result_tmp;
  for (i = 0; i < 9; i++) {
    result->Jinv[i] = result->J[i];
    result->Jphys[i] = result->J[i];
  }
  result->gI[0] = result->rT[0];
  result->gI[1] = result->rT[1];
  result->gI[2] = result->rT[2];
  for (i = 0; i < 8; i++) {
    result->wTabY[i] = result->wTabH[i];
    result->wTabZ[i] = result->wTabH[i];
  }
}

/*
 * Arguments    : void
 * Return Type  : struct1_T
 */
static struct1_T argInit_struct1_T(void)
{
  struct1_T result;
  double result_tmp;
  /* Set the value of each structure field.
Change this value to the value that the application requires. */
  result_tmp = argInit_real_T();
  result.L = result_tmp;
  result.T = result_tmp;
  result.V = result_tmp;
  result.A = result_tmp;
  return result;
}

/*
 * Arguments    : struct2_T *result
 * Return Type  : void
 */
static void argInit_struct2_T(struct2_T *result)
{
  double result_tmp;
  /* Set the value of each structure field.
Change this value to the value that the application requires. */
  result_tmp = argInit_real_T();
  result->dryMass = result_tmp;
  result->landingProp = result_tmp;
  result->m0 = result_tmp;
  result->Lb = result_tmp;
  result->R = result_tmp;
  result->nEngine = result_tmp;
  result->thrustPerEng = result_tmp;
  result->Isp = result_tmp;
  result->throttleMin = result_tmp;
  result->throttleMax = result_tmp;
  result->tvcMax = result_tmp;
  result->tvcRate = result_tmp;
  result->flapMax = result_tmp;
  result->flapMin = result_tmp;
  result->flapTrim = result_tmp;
  result->flapRate = result_tmp;
}

/*
 * Arguments    : struct3_T *result
 * Return Type  : void
 */
static void argInit_struct3_T(struct3_T *result)
{
  double result_tmp;
  /* Set the value of each structure field.
Change this value to the value that the application requires. */
  result_tmp = argInit_real_T();
  argInit_1x4_real_T(result->sigMin);
  result->tolPos = result_tmp;
  result->tolVel = result_tmp;
  result->tolQuat = result_tmp;
  result->tolRate = result_tmp;
  result->tolMass = result_tmp;
  result->tolThr = result_tmp;
  result->tolFlap = result_tmp;
  result->tolSig = result_tmp;
  result->wFuel = result_tmp;
  result->lamVC = result_tmp;
  result->lamTerm = result_tmp;
  result->lamGlide = result_tmp;
  result->reg = result_tmp;
  result->trX = result_tmp;
  result->trU = result_tmp;
  result->trSig = result_tmp;
  result->hMargin = result_tmp;
  result->phaseTight = result_tmp;
  result->wMaxFlip = result_tmp;
  result->wMaxTight = result_tmp;
  result->tiltMax = result_tmp;
  result->glideSlope = result_tmp;
  result->nCone = result_tmp;
  result->coneHalf = result_tmp;
  result->coneShrink = result_tmp;
  result->lcTol = result_tmp;
  result->bellyHold = result_tmp;
  argInit_1x4_real_T(result->qBelly);
  result->softGlide = result_tmp;
  result->monoDescent = result_tmp;
  result->useDrBox = result_tmp;
  argInit_1x2_real_T(result->drBox);
  result->crMax = result_tmp;
  result->thrMaxTight = result_tmp;
  result->wTilt = result_tmp;
  result->wFlap = result_tmp;
  result->rateLim = result_tmp;
  result->sigMax[0] = result->sigMin[0];
  result->sigMax[1] = result->sigMin[1];
  result->sigMax[2] = result->sigMin[2];
  result->sigMax[3] = result->sigMin[3];
}

/*
 * Arguments    : struct4_T *result
 * Return Type  : void
 */
static void argInit_struct4_T(struct4_T *result)
{
  double result_tmp;
  /* Set the value of each structure field.
Change this value to the value that the application requires. */
  result_tmp = argInit_real_T();
  result->maxIter = result_tmp;
  result->fixedIter = result_tmp;
  result->tolPri = result_tmp;
  result->tolDua = result_tmp;
  result->omega = result_tmp;
  result->rho = result_tmp;
  result->checkEvery = result_tmp;
  result->powerIter = result_tmp;
  result->certAfter = result_tmp;
  result->certTol = result_tmp;
  result->certEps = result_tmp;
}

/*
 * Arguments    : struct5_T *result
 * Return Type  : void
 */
static void argInit_struct5_T(struct5_T *result)
{
  double result_tmp;
  /* Set the value of each structure field.
Change this value to the value that the application requires. */
  argInit_14x1_real_T(result->Dx);
  result_tmp = argInit_real_T();
  result->dtau = result_tmp;
  argInit_7x1_real_T(result->Du);
  result->rCtrl = result_tmp;
  result->wTerm = result_tmp;
  result->reg = result_tmp;
  result->maxIter = result_tmp;
  result->fixedIter = result_tmp;
  result->tolPri = result_tmp;
  result->tolDua = result_tmp;
  result->omega = result_tmp;
  result->rho = result_tmp;
  result->checkEvery = result_tmp;
  result->powerIter = result_tmp;
  memcpy(&result->wx[0], &result->Dx[0], 14U * sizeof(double));
}

/*
 * Arguments    : int argc
 *                char **argv
 * Return Type  : int
 */
int main(int argc, char **argv)
{
  (void)argc;
  (void)argv;
  /* The initialize function is being called automatically from your entry-point
   * function. So, a call to initialize is not included here. */
  /* Invoke the entry-point functions.
You can call entry-point functions multiple times. */
  main_scpk_planIterEmb();
  main_scpk_trackStepEmb();
  /* Terminate the application.
You do not need to do this more than one time. */
  gncCore_lib_terminate();
  return 0;
}

/*
 * Arguments    : void
 * Return Type  : void
 */
void main_scpk_planIterEmb(void)
{
  emxArray_real_T *zOut;
  emxArray_real_T *zWarm;
  struct0_T r;
  struct3_T r1;
  struct4_T r2;
  double xl_data[2814];
  double xs_data[2814];
  double ul_data[1400];
  double us_data[1400];
  double tiltN_data[201];
  double dtv_data[200];
  double eng_data[200];
  double gl_data[200];
  double gs_data[200];
  double phase_data[200];
  double dv[14];
  double dv1[12];
  double sigl_data[8];
  double ss_data[8];
  double nu;
  double step;
  int gs_size[2];
  int sigl_size[2];
  int ss_size[2];
  int ul_size[2];
  int us_size[2];
  int xs_size[2];
  int iters;
  int st;
  /* Initialize function 'scpk_planIterEmb' input arguments. */
  /* Initialize function input argument 'x0nd'. */
  /* Initialize function input argument 'xT'. */
  /* Initialize function input argument 'xl'. */
  argInit_14xd201_real_T(xl_data, xs_size);
  /* Initialize function input argument 'ul'. */
  argInit_7xd200_real_T(ul_data, ul_size);
  /* Initialize function input argument 'gl'. */
  argInit_1xd200_real_T(gl_data, xs_size);
  /* Initialize function input argument 'sigl'. */
  argInit_1xd200_real_T(sigl_data, sigl_size);
  /* Initialize function input argument 'phase'. */
  argInit_1xd200_real_T(phase_data, xs_size);
  /* Initialize function input argument 'eng'. */
  argInit_1xd200_real_T(eng_data, xs_size);
  /* Initialize function input argument 'dtv'. */
  argInit_1xd200_real_T(dtv_data, xs_size);
  /* Initialize function input argument 'tiltN'. */
  argInit_1xd200_real_T(tiltN_data, xs_size);
  /* Initialize function input argument 'cfg'. */
  /* Initialize function input argument 'pp'. */
  /* Initialize function input argument 'qp'. */
  /* Initialize function input argument 'zWarm'. */
  zWarm = argInit_d12000x1_real_T();
  /* Call the entry-point 'scpk_planIterEmb'. */
  emxInitArray_real_T(&zOut, 1);
  argInit_14x1_real_T(dv);
  argInit_12x1_real_T(dv1);
  argInit_struct0_T(&r);
  argInit_struct3_T(&r1);
  argInit_struct4_T(&r2);
  scpk_planIterEmb(dv, dv1, xl_data, xs_size, ul_data, ul_size, gl_data,
                   xs_size, sigl_data, sigl_size, phase_data, xs_size, eng_data,
                   xs_size, dtv_data, xs_size, tiltN_data, xs_size, &r, &r1,
                   &r2, zWarm, xs_data, xs_size, us_data, us_size, gs_data,
                   gs_size, ss_data, ss_size, &st, &iters, &nu, &step, zOut);
  emxDestroyArray_real_T(zWarm);
  emxDestroyArray_real_T(zOut);
}

/*
 * Arguments    : void
 * Return Type  : void
 */
void main_scpk_trackStepEmb(void)
{
  struct0_T r;
  struct5_T r1;
  double zWarm_data[1300];
  double zOut_data[1260];
  double xr_data[854];
  double ur_data[420];
  double engk_data[60];
  double dv[14];
  double u0[7];
  double qCmd[4];
  int engk_size[2];
  int ur_size[2];
  int iters;
  int st;
  int zOut_size;
  int zWarm_size;
  /* Initialize function 'scpk_trackStepEmb' input arguments. */
  /* Initialize function input argument 'xcPhys'. */
  /* Initialize function input argument 'xr'. */
  argInit_14xd201_real_T(xr_data, ur_size);
  /* Initialize function input argument 'ur'. */
  argInit_7xd200_real_T(ur_data, ur_size);
  /* Initialize function input argument 'engk'. */
  argInit_1xd200_real_T(engk_data, engk_size);
  /* Initialize function input argument 'cfg'. */
  /* Initialize function input argument 'tp'. */
  /* Initialize function input argument 'zWarm'. */
  zWarm_size = argInit_d1300x1_real_T(zWarm_data);
  /* Call the entry-point 'scpk_trackStepEmb'. */
  argInit_14x1_real_T(dv);
  argInit_struct0_T(&r);
  argInit_struct5_T(&r1);
  scpk_trackStepEmb(dv, xr_data, ur_size, ur_data, ur_size, engk_data,
                    engk_size, &r, &r1, zWarm_data, &zWarm_size, u0, zOut_data,
                    &zOut_size, qCmd, &st, &iters);
}

/*
 * File trailer for main.c
 *
 * [EOF]
 */
