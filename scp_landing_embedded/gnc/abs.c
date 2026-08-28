/*
 * File: abs.c
 *
 * MATLAB Coder version            : 24.2
 * C/C++ source code generated on  : 2026/08/28 22:18:33
 */

/* Include Files */
#include "abs.h"
#include "gncCore_lib_emxutil.h"
#include "gncCore_lib_types.h"
#include "rt_nonfinite.h"
#include <math.h>

/* Function Definitions */
/*
 * Arguments    : const emxArray_real_T *x
 *                emxArray_real_T *y
 * Return Type  : void
 */
void b_abs(const emxArray_real_T *x, emxArray_real_T *y)
{
  const double *x_data;
  double *y_data;
  int k;
  int nx_tmp;
  x_data = x->data;
  nx_tmp = x->size[0];
  k = y->size[0];
  y->size[0] = x->size[0];
  emxEnsureCapacity_real_T(y, k);
  y_data = y->data;
  for (k = 0; k < nx_tmp; k++) {
    y_data[k] = fabs(x_data[k]);
  }
}

/*
 * File trailer for abs.c
 *
 * [EOF]
 */
