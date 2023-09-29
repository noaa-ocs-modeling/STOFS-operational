#! /bin/bash
#############################################################
#Makefile for stofs_3d_atl_netcdf2shef
# Use:
# make - build the executable
# make DEBUG=full - build the executalbe with debug options
# make install - move the built executable into the dir
# make clean - start with a clean slate
###############################################################
# Tunable parameters:
# FC Name of the FORTRAN compiling system to use
# LDFLAGS Options of the loader
# FFLAGS Options of the compiler
# DEBUG Options of the compiler included for debugging
# LIBS List of libraries
# CMD Name of the executable

SRCS=stofs_3d_atl_netcdf2shef.f

OBJS=stofs_3d_atl_netcdf2shef.o

FC = ${COMP_F} 
LDFLAGS = -cpp -DHAVE_NETCDF4 -DNETCDF_CAN_DEFLATE
BINDIR = ../../exec
INCS = -I${G2_INC4} -I${NETCDF_INCLUDES} -I${HDF5_INCLUDES} -I${Z_INC}
LIBS = ${G2_LIB4} ${W3NCO_LIB4} ${W3EMC_LIB4} ${BACIO_LIB4} ${BUFR_LIB4} \
       ${JASPER_LIB} ${PNG_LIB} -L${NETCDF_LIBRARIES}/ -lnetcdf \
       -L${NETCDF_LIBRARIES}/ -lnetcdff -L${HDF5_LIBRARIES}/ -lhdf5 ${Z_LIB}
CMD = stofs_3d_atl_netcdf2shef
FFLAGS = -O2 -fp-model strict $(INCS)

ifeq ($(DEBUG),full)
FFLAGS = -DDEBUG -g -O0 -traceback -check all $(INCS)
endif

# Lines from here on down should not need to be changed.  They are the
# actual rules which make uses to build $(CMD)

all:		$(CMD)

$(CMD):		$(OBJS)
	$(FC) $(LDFLAGS) -o $(@) $(OBJS) $(LIBS)
	rm -f $(OBJS)
#	cp -p $(CMD) ${BINDIR}

install:
	mv $(CMD) ${BINDIR}/

clean:
	rm -f $(OBJS) $(CMD)
