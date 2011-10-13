##############################################################################
### installation prefix; executables are installed in $(PREFIX)/bin
##############################################################################
PREFIX = $(HOME)

##############################################################################
### C compiler
##############################################################################
CC = gcc
#CC = tau_cc.sh

##############################################################################
### test for ccache
##############################################################################
CCACHE = $(shell type ccache 2>/dev/null)

ifneq ($(CCACHE),)
CC := ccache $(CC)
endif

##############################################################################
### set versioning
##############################################################################
VERSION = $(shell svnversion .)
DATE = $(shell date | sed -e 's|[[:space:]]|_|g')

##############################################################################
### set debugging symbols if we are in DEBUGGING mode
##############################################################################
ifdef DEBUGGING
  DEBUG_LIBS = $(shell pkg-config --libs glib-2.0)
  DEBUG_FLAGS = -DDEBUGGING $(shell pkg-config --cflags glib-2.0)
  #Using extra libraries for debugging
else
  DEBUG_LIBS = 
  DEBUG_FLAGS = 
endif

##############################################################################
### Enable experimental features when EXPERIMENTAL is set.
##############################################################################
ifdef EXPERIMENTAL
  DEBUG_FLAGS+= -DEXPERIMENTAL
endif

##############################################################################
### test for architecture to set CFLAGS and LIBFLAGS
##############################################################################
UNAME = $(shell uname)

ifeq ($(HOSTNAME), compute-0-79.local)
FLIBS=-lgfortran
else
FLIBS=-lgfortran
endif 

ifeq ($(UNAME),Linux)
CFLAGS = -Wall -O3 -g -DCMCVERSION="\"$(VERSION)\"" -DCMCDATE="\"$(DATE)\"" $(DEBUG_FLAGS)
#CFLAGS = -Wall -g -DCMCVERSION="\"$(VERSION)\"" -DCMCDATE="\"$(DATE)\"" $(DEBUG_FLAGS)
LIBFLAGS = -lpthread -lz -lgsl -lgslcblas -lcfitsio $(FLIBS) -lm $(DEBUG_LIBS)
else

ifeq ($(UNAME),Darwin)
CC = gcc
#CFLAGS = -Wall -O3 -I/sw/include -I/sw/include/gnugetopt -I/opt/local/include -L/sw/lib -L/opt/local/lib -L/sw/lib/gcc4.4/lib -DCMCVERSION="\"$(VERSION)\"" -DCMCDATE="\"$(DATE)\""
#CFLAGS = -Wall -O3 -I/sw/include -I/sw/include/gnugetopt -I/opt/local/include -L/sw/lib -L/opt/local/lib -L/sw/lib/gcc4.4/lib -DCMCVERSION="\"$(VERSION)\"" -DCMCDATE="\"$(DATE)\""
#CFLAGS = -m32 -Wall -O3 -g -I/sw/include -I/sw/include/gnugetopt -I/opt/local/include -L/sw/lib -L/opt/local/lib -L/sw/lib/gcc4.4/lib -DCMCVERSION="\"$(VERSION)\"" -DCMCDATE="\"$(DATE)\""
CFLAGS = -Wall -O3 -g -I/sw/include -I/sw/include/gnugetopt -I/opt/local/include -L/sw/lib -L/opt/local/lib -L/sw/lib/gcc4.4/lib -DCMCVERSION="\"$(VERSION)\"" -DCMCDATE="\"$(DATE)\""
#CFLAGS = -Wall -O3 -I/sw/include -L/sw/lib -DCMCVERSION="\"$(VERSION)\"" -DCMCDATE="\"$(DATE)\""
#CFLAGS = -Wall -O3 -I/opt/local/include -L/opt/local/lib -DCMCVERSION="\"$(VERSION)\"" -DCMCDATE="\"$(DATE)\""
LIBFLAGS = -lz -lgsl -lgslcblas -lcfitsio $(FLIBS) -lm
else

ifeq ($(UNAME),AIX)
CFLAGS = -Wall -O3 -I/u/ac/fregeau/local/include -L/u/ac/fregeau/local/lib -I/usr/local/include -L/usr/local/lib -DCMCVERSION="\"$(VERSION)\"" -DCMCDATE="\"$(DATE)\""
LIBFLAGS = -lz -lgsl -lgslcblas -lcfitsio -liberty $(FLIBS) -lm
else
CFLAGS = -Wall -O3 -DCMCVERSION="\"$(VERSION)\"" -DCMCDATE="\"$(DATE)\""
LIBFLAGS = -lpthread -lz -lgsl -lgslcblas -lcfitsio $(FLIBS) -lm
endif
endif
endif

##############################################################################
### extra C flags
##############################################################################
# possibilities: 
# -DUSE_THREADS	(using threads, results will change due different RNGs)
# -DUSE_THREADS_SORT	(using threads, for sorting only, results should
# 					remain the same)
# -DUSE_FIND	(using Hoare's FIND for parallel sorting)
# -DUSE_MODIFIND	(using Zabrodsky's MODIFIND)
# 	(the default for the above two is to use Floyd and Rivest's SELECT)
# some gcc flags
#CFLAGS := $(CFLAGS) -malign-double -fomit-frame-pointer -fmove-all-movables
# Ato's debugging
#CFLAGS = -Wall -pedantic -ggdb
# Intel compiler
#CFLAGS = -O2 -mp -unroll -pc80 -tpp7 -xiMKW
# Portland Group compiler
#CFLAGS = -B -O4 -Minform,warn

##############################################################################
### special hosts
##############################################################################
ifeq ($(HOSTNAME),master.cluster)
CFLAGS := $(CFLAGS) -march=athlon-mp -I/opt/gsl/include -L/opt/gsl/lib
LIBFLAGS := $(LIBFLAGS) -static
endif

ifeq ($(HOSTNAME),fugu.phys.northwestern.edu)
#CC = pathcc
#CFLAGS = -Wall -O3 $(DEBUG_FLAGS) -DCMCVERSION="\"$(VERSION)\"" -DCMCDATE="\"$(DATE)\""
#CFLAGS := -Wall -Ofast -OPT:fast_math=on -LNO:fu=9:full_unroll_size=7000 -static-data -I/usr/include/cfitsio
#CFLAGS := $(CFLAGS) -march=opteron -I/usr/include/cfitsio
#CC = gcc
CFLAGS := $(CFLAGS) -march=k8 -I/export/apps/gsl-1.9/include -I/export/apps/cfitsio/include -L/export/apps/gsl-1.9/lib -L/export/apps/cfitsio/lib -L/usr/lib -L/usr/lib/gcc/x86_64-redhat-linux/3.4.6/
#CFLAGS := $(CFLAGS) -march=k8 -I/usr/include/cfitsio
#CFLAGS := $(CFLAGS) -m32 -march=k8 -I/share/apps/gsl/include -L/share/apps/gsl/lib -I/share/apps/cfitsio/include -L/share/apps/cfitsio/lib $(DEBUG_FLAGS)
#LIBFLAGS := $(LIBFLAGS) -static 
#LIBFLAGS := $(LIBFLAGS) 
endif

ifeq ($(HOSTNAME), compute-0-79.local)
CFLAGS := $(CFLAGS) -march=k8 -I/share/apps/gsl/include -L/share/apps/gsl/lib -I/share/apps/cfitsio/include -L/share/apps/cfitsio/lib $(DEBUG_FLAGS)
CFLAGS := `mpicc -showme:compile` $(CFLAGS)
LIBFLAGS := $(LIBFLAGS) -L/usr/local/cuda/lib 
LIBFLAGS := $(LIBFLAGS) `mpicc -showme:link`
endif

DOMNAME = $(shell hostname | cut -d . -f 2-)
ifeq ($(DOMNAME),ncsa.uiuc.edu)
CC = icc
CFLAGS := -wd864,1188 -I $(HOME)/libs_et_al/include
# redefine libflags, leave out -lm to link with intel math library
# turn of diagn. 864: extern inline function ... was referenced but not defined
#           and 1188: floating-point value cannot be represented exactly
LIBFLAGS = -lpthread -lz -lgsl -lgslcblas -lcfitsio -lg2c
LIBFLAGS := $(LIBFLAGS) -L $(HOME)/libs_et_al/lib -static
endif

FEWBODYDIR = fewbody-0.24
BSEDIR = bse_wrap/bse
BSEWRAPDIR = bse_wrap
CUDADIR = cuda

##############################################################################
#----------- CUDA suppport ----------------#
#determines if cuda is compiled and if emulation mode
##############################################################################
use_cuda=0
emu=0

ifeq ($(use_cuda), 1)
CFLAGS   += -DUSE_CUDA
CUDAOBJS = $(CUDADIR)/cmc_cuda.cu_o
CUDAINC  = -I./$(CUDADIR)/common/inc
CFLAGS	 += -L/usr/local/cuda/lib64 -L./$(CUDADIR)/common/lib -L./$(CUDADIR)/lib
CUDALIB  = -fPIC -lcuda -lcudart
ifeq ($(emu), 1)
CFLAGS 	+= -D__DEVICE_EMULATION__
endif 
endif

##############################################################################
#----------- MPI suppport ----------------#
##############################################################################
use_mpi=0

ifeq ($(use_mpi), 1)
CFLAGS   += -DUSE_MPI
MPIOBJS = cmc_mpi.o
CFLAGS := `mpicc -showme:compile` $(CFLAGS)
LIBFLAGS := $(LIBFLAGS) `mpicc -showme:link`
endif

##############################################################################
#----------- MPI suppport ----------------#
##############################################################################
simul=0

ifneq ($(simul), 0)
CFLAGS   += -DSIMUL=$(simul)
endif
