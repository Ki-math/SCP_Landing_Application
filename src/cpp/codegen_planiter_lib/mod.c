/*
 * File: mod.c
 *
 * MATLAB Coder version            : 24.2
 * C/C++ source code generated on  : 2026/08/28 19:09:09
 */

/* Include Files */
#include "mod.h"
#include "rt_nonfinite.h"
#include "rt_nonfinite.h"
#include <math.h>

/* Function Definitions */
/*
 * Arguments    : double x
 *                double y
 * Return Type  : double
 */
double b_mod(double x, double y)
{
  double r;
  r = x;
  if (!(y == 0.0)) {
    if (rtIsNaN(x) || rtIsNaN(y) || rtIsInf(x)) {
      r = rtNaN;
    } else if (rtIsInf(y)) {
      if (y < 0.0) {
        r = y;
      }
    } else {
      bool rEQ0;
      r = fmod(x, y);
      rEQ0 = (r == 0.0);
      if ((!rEQ0) && (y > floor(y))) {
        double q;
        q = fabs(x / y);
        rEQ0 = !(fabs(q - floor(q + 0.5)) > 2.2204460492503131E-16 * q);
      }
      if (rEQ0) {
        r = y * 0.0;
      } else if (y < 0.0) {
        r += y;
      }
    }
  }
  return r;
}

/*
 * File trailer for mod.c
 *
 * [EOF]
 */
