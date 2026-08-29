/*
 * File: eye.c
 *
 * MATLAB Coder version            : 24.2
 * C/C++ source code generated on  : 2026/08/29 11:14:48
 */

/* Include Files */
#include "eye.h"
#include "rt_nonfinite.h"
#include <string.h>

/* Function Definitions */
/*
 * Arguments    : double b_I[196]
 * Return Type  : void
 */
void eye(double b_I[196])
{
  int k;
  memset(&b_I[0], 0, 196U * sizeof(double));
  for (k = 0; k < 14; k++) {
    b_I[k + 14 * k] = 1.0;
  }
}

/*
 * File trailer for eye.c
 *
 * [EOF]
 */
