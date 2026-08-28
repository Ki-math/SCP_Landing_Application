/* pipg_core_testmex.cpp — pipg_core.hpp の検証用MEX (パッケージには含めない).
 * [z,st,it,rp,rd] = pipg_core_testmex(Pdiag,q,C,d,neq,lb,ub,opt,z0,w0)
 */
#include "mex.h"
#include "pipg_core.hpp"
#include <vector>

static double gf(const mxArray *s, const char *n) {
    const mxArray *f = mxGetField(s,0,n);
    if (!f) mexErrMsgIdAndTxt("t:o","opt.%s missing",n);
    return mxGetScalar(f);
}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    int32_t m = (int32_t)mxGetM(prhs[2]);
    int32_t n = (int32_t)mxGetN(prhs[2]);
    const mwIndex *mir = mxGetIr(prhs[2]);
    const mwIndex *mjc = mxGetJc(prhs[2]);
    std::vector<int32_t> ir(mjc[n]), jc(n+1);
    for (mwIndex k = 0; k < mjc[n]; ++k) ir[k] = (int32_t)mir[k];
    for (int32_t j = 0; j <= n; ++j) jc[j] = (int32_t)mjc[j];

    pipg::Opt o;
    o.maxIter=(int)gf(prhs[7],"maxIter"); o.fixedIter=(int)gf(prhs[7],"fixedIter");
    o.tolPri=gf(prhs[7],"tolPri"); o.tolDua=gf(prhs[7],"tolDua");
    o.omega=gf(prhs[7],"omega"); o.rho=gf(prhs[7],"rho");
    o.checkEvery=(int)gf(prhs[7],"checkEvery"); o.powerIter=(int)gf(prhs[7],"powerIter");
    o.certAfter=(int)gf(prhs[7],"certAfter"); o.certTol=gf(prhs[7],"certTol");
    o.certEps=gf(prhs[7],"certEps");

    plhs[0] = mxCreateDoubleMatrix(n,1,mxREAL);
    double *z = mxGetPr(plhs[0]);
    memcpy(z, mxGetPr(prhs[8]), n*sizeof(double));
    std::vector<double> w(m);
    memcpy(w.data(), mxGetPr(prhs[9]), m*sizeof(double));

    int iters=0; double rp=0, rd=0;
    int st = pipg_solve_csc(mxGetPr(prhs[0]), mxGetPr(prhs[1]), n, m,
                            (int32_t)mxGetScalar(prhs[4]), jc.data(), ir.data(),
                            mxGetPr(prhs[2]), mxGetPr(prhs[3]),
                            mxGetPr(prhs[5]), mxGetPr(prhs[6]), &o, z, w.data(),
                            &iters, &rp, &rd);
    if (nlhs>1) plhs[1]=mxCreateDoubleScalar(st);
    if (nlhs>2) plhs[2]=mxCreateDoubleScalar(iters);
    if (nlhs>3) plhs[3]=mxCreateDoubleScalar(rp);
    if (nlhs>4) plhs[4]=mxCreateDoubleScalar(rd);
}
