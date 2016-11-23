###############################################################
#
# Location of code (in $ROOT) and location where model is to be built $BIN
#
ROOT      :=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
BIN       = $(ROOT)/bin
ARCH      := $(shell uname)
#
# Generic Variables
#
SRC         =$(ROOT)/src
SRC_UTIL    =$(SRC)/src_util
SRC_LES     =$(SRC)/src_LES
SRC_SALSA   =$(SRC)/src_salsa

VPATH = $(SRC_LES):$(SRC_SALSA):$(SRC_UTIL):$(SRC)

ECHO    = /bin/echo
RM      = /bin/rm -f

NETCDFROOT         = /opt/cray/netcdf/4.3.0/intel/130
NETCDF_LIB         = -L$(NETCDFROOT)/lib -lnetcdff -lnetcdf
NETCDF_INCLUDE     = -I$(NETCDFROOT)/include

HDF5ROOT           = /opt/cray/hdf5/1.8.11/intel/130
HDF5_LIB           = -L$(HDF5ROOT)/lib -lhdf5_hl -lhdf5
HDF5_INCLUDE       = -I$(HDF5ROOT)/include
LIBS = '$(HDF5_LIB) $(NETCDF_LIB)'

ARCHIVE = ar rs
RANLIB =:
SEQFFLAGS = -I$(SRC) $(HDF5_INCLUDE) $(NETCDF_INCLUDE)
MPIFFLAGS = -I$(SRC) $(HDF5_INCLUDE) $(NETCDF_INCLUDE)

F90 = ftn
MPIF90 = ftn
FFLAGS =  -O2 -msse2 -fp-model source -fp-model precise -g -traceback -convert big_endian -integer-size 32 -real-size 64 -check bounds -fpe0
F77FLAGS = -O2 -msse2 -fp-model source -fp-model precise -g -traceback -convert big_endian -integer-size 32 -real-size 64 -check bounds -fpe0


LES_OUT_MPI=$(BIN)/les.mpi

LES_OUT_SEQ=$(BIN)/les.seq

default: mpi

all:  mpi seq

seq: $(LES_OUT_SEQ)

mpi: $(LES_OUT_MPI)

$(LES_OUT_SEQ): 
	cd $(SRC); $(MAKE) LES_ARC=seq \
	FFLAGS='$(FFLAGS) $(SEQFFLAGS)' F90=$(F90) \
	F77FLAGS='$(F77FLAGS)' OUT=$(LES_OUT_SEQ) \
	LIBS=$(LIBS) SRCUTIL=$(SRC_UTIL) SRCLES=$(SRC_LES) \
	SRCSALSA=$(SRC_SALSA)

$(LES_OUT_MPI):
	cd $(SRC); $(MAKE) LES_ARC=mpi \
	FFLAGS='$(FFLAGS) $(MPIFFLAGS)' F90=$(MPIF90)  \
	F77FLAGS='$(F77FLAGS)' OUT=$(LES_OUT_MPI) \
	LIBS=$(LIBS) SRCUTIL=$(SRC_UTIL) SRCLES=$(SRC_LES) \
	SRCSALSA=$(SRC_SALSA)

.PHONY: $(LES_OUT_SEQ) 
.PHONY: $(LES_OUT_MPI)

#
# cleaning
# --------------------
#
clean: cleanmpi cleanseq 
	$(RM) $(SRC)/*mod $(SRC)/*.o

cleanmpi:
	$(ECHO) "cleaning mpi model"
	$(RM) core $(LES_OUT_MPI) $(SRC)/mpi/*mod $(LES_ARC_MPI)

cleanseq:
	$(ECHO) "clean sequential model"
	$(RM) core $(LES_OUT_SEQ) $(SRC)/seq/*mod $(LES_ARC_SEQ)

FORCE: 
.PRECIOUS: $(LIBS)