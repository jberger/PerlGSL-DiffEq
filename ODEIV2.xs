#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <gsl/gsl_errno.h>
#include <gsl/gsl_odeiv2.h>
#include <gsl/gsl_version.h>

char* get_gsl_version () {
  return GSL_VERSION;
}

struct params {
  int num;
  SV* eqn;
};

int diff_eqs (double t, const double y[], double f[], void *params) {

  dSP;

  SV* eqn = ((struct params *)params)->eqn;
  int num = ((struct params *)params)->num;
  int count;
  int i;

  ENTER;
  SAVETMPS;

  PUSHMARK(SP);

  XPUSHs(sv_2mortal(newSVnv(t)));

  for (i = 1; i <= num; i++) {
    XPUSHs(sv_2mortal(newSVnv(y[i-1])));
  }
  PUTBACK;

  count = call_sv(eqn, G_ARRAY);
  if (count != num) 
    warn("Equation did not return the specified number of values");

  SPAGAIN;

  for (i = 1; i <= num; i++) {
    f[num-i] = POPn;
  }
  PUTBACK;

  FREETMPS;
  LEAVE;

  return GSL_SUCCESS;

}

SV* c_ode_solver (SV* eqn, double t1, double t2, int steps, int stepper) {

  dSP;

  int num;
  int i;
  int j;
  double t = t1;
  double y[num];
  AV* ret = newAV();
  gsl_odeiv2_step_type * step_type;

  // create stepper, selected with $opt->{type}
  // then .pm converts user choice to number
  if (stepper == 1) {
    step_type = gsl_odeiv2_step_rk2;
  } else if (stepper == 2) {
    step_type = gsl_odeiv2_step_rk4;
  } else if (stepper == 3) {
    step_type = gsl_odeiv2_step_rkf45;
  } else if (stepper == 4) {
    step_type = gsl_odeiv2_step_rkck;
  } else if (stepper == 5) {
    step_type = gsl_odeiv2_step_rk8pd;
  } else {
    warn("Could not determine step type, using rk8pd");
    step_type = gsl_odeiv2_step_rk8pd;
  }

  ENTER;
  SAVETMPS;

  PUSHMARK(SP);

  num = call_sv(eqn, G_ARRAY|G_NOARGS);

  SPAGAIN;

  for (i = 1; i <= num; i++) {
    y[num-i] = POPn;
  }
  PUTBACK;

  FREETMPS;
  LEAVE;

  struct params myparams;
  myparams.num = num;
  myparams.eqn = eqn;

  gsl_odeiv2_system sys = {diff_eqs, NULL, num, &myparams};
     
  gsl_odeiv2_driver * d = 
    gsl_odeiv2_driver_alloc_y_new (&sys, step_type,
   				    1e-6, 1e-6, 0.0);
     
  for (i = 1; i <= steps; i++)
    {
      double ti = i * t2 / steps;
      int status = gsl_odeiv2_driver_apply (d, &t, ti, y);
     
      if (status != GSL_SUCCESS)
        {
          warn("error, return value=%d\n", status);
          break;
        }

      AV* data = newAV();
      av_push(data, newSVnv(t));
      for (j = 0; j < num; j++) {
        av_push(data, newSVnv(y[j]));
      }

      av_push(ret, newRV_inc((SV *)data));
    }
     
  gsl_odeiv2_driver_free (d);

  return newRV_inc((SV *)ret);
}


MODULE = Math::GSLx::ODEIV2	PACKAGE = Math::GSLx::ODEIV2	

PROTOTYPES: DISABLE


char *
get_gsl_version ()

SV *
c_ode_solver (eqn, t1, t2, steps, stepper)
	SV *	eqn
	double	t1
	double	t2
	int	steps
	int	stepper
