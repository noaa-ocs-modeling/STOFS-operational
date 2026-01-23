FC=${COMP_F} #WCOSS2
OPT= -O2 -cpp -CB -mcmodel=medium -assume byterecl -traceback

#LIB= -I$(TACC_NETCDF_DIR)/include -L$(TACC_NETCDF_DIR)/lib -lnetcdf -lnetcdff
LIB= -I$(NETCDF)/include -L$(NETCDF)/lib -lnetcdf -lnetcdff

main: argparse.mod
	$(FC) $(OPT) -o stofs_3d_atl_combine_hotstart stofs_3d_atl_combine_hotstart.f90 argparse.f90 $(LIB)
argparse.mod: 
	$(FC) $(OPT) -c argparse.f90 
clean:
	rm -f ./*.o ./*.mod ./stofs_3d_atl_combine_hotstart
