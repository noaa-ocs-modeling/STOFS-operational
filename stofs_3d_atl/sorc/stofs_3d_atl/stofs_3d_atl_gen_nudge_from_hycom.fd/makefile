
#FC=${COMP_F}
FC=ifort #Frontera

#FC=${COMP_F} #WCOSS2


OPT= -O2 -CB -mcmodel=medium 

#LIB= -I$(TACC_NETCDF_DIR)/include -L$(TACC_NETCDF_DIR)/lib -lnetcdf -lnetcdff
LIB= -I$(NETCDF)/include -L$(NETCDF)/lib -lnetcdf -lnetcdff

all: compute_zcor.mod pt_in_poly_test.mod 
	$(FC) $(OPT) -o stofs_3d_atl_gen_nudge_from_hycom stofs_3d_atl_gen_nudge_from_hycom.f90 ./UtilLib/compute_zcor.f90 ./UtilLib/pt_in_poly_test.f90 $(LIB)

debug: compute_zcor.mod pt_in_poly_test.mod
	$(FC) $(OPT) -o stofs_3d_atl_gen_nudge_from_hycom stofs_3d_atl_gen_nudge_from_hycom.f90 ./UtilLib/compute_zcor.f90 ./UtilLib/pt_in_poly_test.f90 $(LIB)

install: all
	mkdir build; cp stofs_3d_atl_gen_nudge_from_hycom ./build

compute_zcor.mod:
	$(FC) $(OPT) -c ./UtilLib/compute_zcor.f90

pt_in_poly_test.mod:
	$(FC) $(OPT) -c ./UtilLib/pt_in_poly_test.f90

clean:
	rm -f ./*.o ./*.mod ./stofs_3d_atl_gen_nudge_from_hycom; rm -rf ./build


