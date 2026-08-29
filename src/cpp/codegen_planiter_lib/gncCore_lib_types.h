/*
 * File: gncCore_lib_types.h
 *
 * MATLAB Coder version            : 24.2
 * C/C++ source code generated on  : 2026/08/29 11:14:48
 */

#ifndef GNCCORE_LIB_TYPES_H
#define GNCCORE_LIB_TYPES_H

/* Include Files */
#include "rtwtypes.h"

/* Type Definitions */
#ifndef typedef_struct1_T
#define typedef_struct1_T
typedef struct {
  double L;
  double T;
  double V;
  double A;
} struct1_T;
#endif /* typedef_struct1_T */

#ifndef typedef_struct2_T
#define typedef_struct2_T
typedef struct {
  double dryMass;
  double landingProp;
  double m0;
  double Lb;
  double R;
  double nEngine;
  double thrustPerEng;
  double Isp;
  double throttleMin;
  double throttleMax;
  double tvcMax;
  double tvcRate;
  double flapMax;
  double flapMin;
  double flapTrim;
  double flapRate;
} struct2_T;
#endif /* typedef_struct2_T */

#ifndef typedef_struct4_T
#define typedef_struct4_T
typedef struct {
  double maxIter;
  double fixedIter;
  double tolPri;
  double tolDua;
  double omega;
  double rho;
  double checkEvery;
  double powerIter;
  double certAfter;
  double certTol;
  double certEps;
} struct4_T;
#endif /* typedef_struct4_T */

#ifndef typedef_struct5_T
#define typedef_struct5_T
typedef struct {
  double dtau;
  double Dx[14];
  double Du[7];
  double wx[14];
  double rCtrl;
  double wTerm;
  double reg;
  double maxIter;
  double fixedIter;
  double tolPri;
  double tolDua;
  double omega;
  double rho;
  double checkEvery;
  double powerIter;
} struct5_T;
#endif /* typedef_struct5_T */

#ifndef typedef_struct0_T
#define typedef_struct0_T
typedef struct {
  struct1_T sc;
  struct2_T veh;
  double m0;
  double Fs;
  double J[9];
  double Jinv[9];
  double Jphys[9];
  double Tmin1;
  double Tmax1;
  double nEng;
  double Tmin;
  double Tmax;
  double tanGim;
  double alpha;
  double rT[3];
  double gI[3];
  double cx;
  double cy;
  double cz;
  double LoverD;
  double cL;
  double rho;
  double aeroScale;
  double surfMode;
  double V2ref;
  double Bflap[12];
  double cFlapDrag;
  double jacStep;
  double vEps;
  double tEps;
  double mhatMin;
  double wMax;
  double hmin;
  double atmIsa;
  double hPad;
  double wOn;
  double wTabH[8];
  double wTabY[8];
  double wTabZ[8];
} struct0_T;
#endif /* typedef_struct0_T */

#ifndef typedef_struct3_T
#define typedef_struct3_T
typedef struct {
  double tolPos;
  double tolVel;
  double tolQuat;
  double tolRate;
  double tolMass;
  double tolThr;
  double tolFlap;
  double tolSig;
  double wFuel;
  double lamVC;
  double lamTerm;
  double lamGlide;
  double reg;
  double trX;
  double trU;
  double trSig;
  double sigMin[4];
  double sigMax[4];
  double hMargin;
  double phaseTight;
  double wMaxFlip;
  double wMaxTight;
  double tiltMax;
  double glideSlope;
  double nCone;
  double coneHalf;
  double coneShrink;
  double lcTol;
  double bellyHold;
  double qBelly[4];
  double softGlide;
  double monoDescent;
  double useDrBox;
  double drBox[2];
  double crMax;
  double thrMaxTight;
  double wTilt;
  double wFlap;
  double rateLim;
} struct3_T;
#endif /* typedef_struct3_T */

#ifndef struct_emxArray_real_T
#define struct_emxArray_real_T
struct emxArray_real_T {
  double *data;
  int *size;
  int allocatedSize;
  int numDimensions;
  bool canFreeData;
};
#endif /* struct_emxArray_real_T */
#ifndef typedef_emxArray_real_T
#define typedef_emxArray_real_T
typedef struct emxArray_real_T emxArray_real_T;
#endif /* typedef_emxArray_real_T */

#endif
/*
 * File trailer for gncCore_lib_types.h
 *
 * [EOF]
 */
