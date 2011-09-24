/* -*- linux-c -*- */

#include <stdio.h>
#include <zlib.h>
#include <math.h>
#include "cmc.h"
#include "cmc_vars.h"

/* calculate the units used */
void bb_calcunits(fb_obj_t *obj[2], fb_units_t *bb_units)
{
	bb_units->v = sqrt(FB_CONST_G*(obj[0]->m + obj[1]->m)/(obj[0]->m * obj[1]->m) * \
			(obj[0]->obj[0]->m * obj[0]->obj[1]->m / obj[0]->a + \
			 obj[1]->obj[0]->m * obj[1]->obj[1]->m / obj[1]->a));
	bb_units->l = obj[0]->a + obj[1]->a;
	bb_units->t = bb_units->l / bb_units->v;
	bb_units->m = bb_units->l * fb_sqr(bb_units->v) / FB_CONST_G;
	bb_units->E = bb_units->m * fb_sqr(bb_units->v);
}

/* the main attraction */
fb_ret_t binbin(double *t, long k, long kp, double W, double bmax, fb_hier_t *hier, gsl_rng *rng)
{
	int j;
	long jbin, jbinp;
	double vc, b, rtid, m0, m1, a0, a1, e0, e1, m00, m01, m10, m11;
	fb_units_t fb_units;
	fb_input_t input;
	fb_ret_t retval;

	/* a useful definition */
	jbin = star[k].binind;
	jbinp = star[kp].binind;

	/* v_inf should be in units of v_crit */
#ifdef USE_MPI
	vc = sqrt((star_m[k]+star_m[kp])/(star_m[k]*star_m[kp])*
		  (binary[jbin].m1*binary[jbin].m2/binary[jbin].a + 
		   binary[jbinp].m1*binary[jbinp].m2/binary[jbinp].a)/((double) clus.N_STAR));
#else
	vc = sqrt((star[k].m+star[kp].m)/(star[k].m*star[kp].m)*
		  (binary[jbin].m1*binary[jbin].m2/binary[jbin].a + 
		   binary[jbinp].m1*binary[jbinp].m2/binary[jbinp].a)/((double) clus.N_STAR));
#endif

#ifndef USE_MPI
	curr_st = &st[findProcForIndex(k)];
#endif
	/* b should be in units of a */
	b = sqrt(rng_t113_dbl_new(curr_st)) * bmax / (binary[jbin].a + binary[jbinp].a);

	/* set parameters */
	input.ks = 0;
	input.tstop = 1.0e7;
	input.Dflag = 0;
	input.dt = 0.0;
	input.tcpustop = 60.0;
	input.absacc = 1.0e-9;
	input.relacc = 1.0e-9;
	input.ncount = 500;
	input.tidaltol = 1.0e-5;
	input.firstlogentry[0] = '\0';
	input.fexp = 1.0;
	fb_debug = 0;
	
	/* initialize a few things for integrator */
	*t = 0.0;
	hier->nstar = 4;
	fb_init_hier(hier);
	
	/* create binaries */
	hier->hier[hier->hi[2]+0].obj[0] = &(hier->hier[hier->hi[1]+0]);
	hier->hier[hier->hi[2]+0].obj[1] = &(hier->hier[hier->hi[1]+1]);
	hier->hier[hier->hi[2]+0].t = *t;
	hier->hier[hier->hi[2]+1].obj[0] = &(hier->hier[hier->hi[1]+2]);
	hier->hier[hier->hi[2]+1].obj[1] = &(hier->hier[hier->hi[1]+3]);
	hier->hier[hier->hi[2]+1].t = *t;

	/* give the objects some properties */
	for (j=0; j<hier->nstar; j++) {
		hier->hier[hier->hi[1]+j].ncoll = 1;
		sprintf(hier->hier[hier->hi[1]+j].idstring, "%d", j);
		hier->hier[hier->hi[1]+j].n = 1;
		hier->hier[hier->hi[1]+j].obj[0] = NULL;
		hier->hier[hier->hi[1]+j].obj[1] = NULL;
		hier->hier[hier->hi[1]+j].Lint[0] = 0.0;
		hier->hier[hier->hi[1]+j].Lint[1] = 0.0;
		hier->hier[hier->hi[1]+j].Lint[2] = 0.0;
	}

	hier->hier[hier->hi[1]+0].id[0] = binary[jbin].id1;
	hier->hier[hier->hi[1]+1].id[0] = binary[jbin].id2;
	hier->hier[hier->hi[1]+2].id[0] = binary[jbinp].id1;
	hier->hier[hier->hi[1]+3].id[0] = binary[jbinp].id2;

	if (SS_COLLISION) {
		hier->hier[hier->hi[1]+0].R = binary[jbin].rad1 * units.l;
		hier->hier[hier->hi[1]+1].R = binary[jbin].rad2 * units.l;
		hier->hier[hier->hi[1]+2].R = binary[jbinp].rad1 * units.l;
		hier->hier[hier->hi[1]+3].R = binary[jbinp].rad2 * units.l;
	} else {
		hier->hier[hier->hi[1]+0].R = 0.0;
		hier->hier[hier->hi[1]+1].R = 0.0;
		hier->hier[hier->hi[1]+2].R = 0.0;
		hier->hier[hier->hi[1]+3].R = 0.0;
	}

	hier->hier[hier->hi[1]+0].m = binary[jbin].m1 * units.mstar;
	hier->hier[hier->hi[1]+1].m = binary[jbin].m2 * units.mstar;
	hier->hier[hier->hi[1]+2].m = binary[jbinp].m1 * units.mstar;
	hier->hier[hier->hi[1]+3].m = binary[jbinp].m2 * units.mstar;

	hier->hier[hier->hi[2]+0].m = hier->hier[hier->hi[1]+0].m + hier->hier[hier->hi[1]+1].m;
	hier->hier[hier->hi[2]+1].m = hier->hier[hier->hi[1]+2].m + hier->hier[hier->hi[1]+3].m;

	hier->hier[hier->hi[1]+0].Eint = binary[jbin].Eint1 * units.E;
	hier->hier[hier->hi[1]+1].Eint = binary[jbin].Eint2 * units.E;
	hier->hier[hier->hi[1]+2].Eint = binary[jbinp].Eint1 * units.E;
	hier->hier[hier->hi[1]+3].Eint = binary[jbinp].Eint2 * units.E;

	hier->hier[hier->hi[2]+0].a = binary[jbin].a * units.l;
	hier->hier[hier->hi[2]+1].a = binary[jbinp].a * units.l;
	
	hier->hier[hier->hi[2]+0].e = binary[jbin].e;
	hier->hier[hier->hi[2]+1].e = binary[jbinp].e;

	hier->obj[0] = &(hier->hier[hier->hi[2]+0]);
	hier->obj[1] = &(hier->hier[hier->hi[2]+1]);
	hier->obj[2] = NULL;
	hier->obj[3] = NULL;

	/* logging */
	fprintf(binintfile, "********************************************************************************\n");
	fprintf(binintfile, "type=BB t=%.9g\n", TotalTime);
	fprintf(binintfile, "params: b=%g v=%g\n", b, W/vc);
	/* set units to 1 since we're already in CGS */
	fb_units.v = fb_units.l = fb_units.t = fb_units.m = fb_units.E = 1.0;
	fprintf(binintfile, "input: ");
	binint_log_obj(hier->obj[0], fb_units);
	fprintf(binintfile, "input: ");
	binint_log_obj(hier->obj[1], fb_units);
	
	/* get the units and normalize */
	bb_calcunits(hier->obj, &fb_units);
	fb_normalize(hier, fb_units);
	
	m0 = hier->obj[0]->m;
	m1 = hier->obj[1]->m;
	a0 = hier->obj[0]->a;
	a1 = hier->obj[1]->a;
	e0 = hier->obj[0]->e;
	e1 = hier->obj[1]->e;
	m00 = hier->obj[0]->obj[0]->m;
	m01 = hier->obj[0]->obj[1]->m;
	m10 = hier->obj[1]->obj[0]->m;
	m11 = hier->obj[1]->obj[1]->m;

	rtid = pow(2.0*m0*m1/input.tidaltol, 1.0/3.0) * \
		FB_MAX(pow(m00*m01, -1.0/3.0)*a0*(1.0+e0), pow(m10*m11, -1.0/3.0)*a1*(1.0+e1));

	fb_init_scattering(hier->obj, W/vc, b, rtid);
	
	/* trickle down the binary properties, then back up */
	for (j=0; j<2; j++) {
		fb_randorient(&(hier->hier[hier->hi[2]+j]), rng, curr_st);
		fb_downsync(&(hier->hier[hier->hi[2]+j]), *t);
		fb_upsync(&(hier->hier[hier->hi[2]+j]), *t);
	}
	
	/* call fewbody! */
	retval = fewbody(input, hier, t);

	/* and return */
	return(retval);
}
