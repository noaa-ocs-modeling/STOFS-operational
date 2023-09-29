FC = ${COMP_F}

#FC=ifort #Frontera
#FC=${COMP_F} #WCOSS2


all: stofs_3d_atl_tide_fac.f90 tf_selfe.f90
	        $(FC) -o stofs_3d_atl_tide_fac  stofs_3d_atl_tide_fac.f90 tf_selfe.f90 
debug: stofs_3d_atl_tide_fac.f90 tf_selfe.f90
	        $(FC) -g -o stofs_3d_atl_tide_fac  stofs_3d_atl_tide_fac.f90 tf_selfe.f90 
install: all
	        mkdir build; cp stofs_3d_atl_tide_fac  build/
clean:
	        rm -f ./*.o ./stofs_3d_atl_tide_fac;rm -rf ./build

