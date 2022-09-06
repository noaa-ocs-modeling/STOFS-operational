FC = ${COMP_F}

#FC=ifort #Frontera
#FC=${COMP_F} #WCOSS2

main: stofs_3d_atl_tide_fac.f90 tf_selfe.f90
	$(FC) -o stofs_3d_atl_tide_fac stofs_3d_atl_tide_fac.f90 tf_selfe.f90 
clean:
	rm -f ./*.o ./stofs_3d_atl_tide_fac


