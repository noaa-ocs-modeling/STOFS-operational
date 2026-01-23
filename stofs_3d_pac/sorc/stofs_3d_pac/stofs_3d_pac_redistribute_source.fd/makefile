FC = ${COMP_F}

#FC=ifort #Frontera
#FC=${COMP_F} #WCOSS2


all: stofs_3d_pac_redistribute_source.f90
	        $(FC) -o stofs_3d_pac_redistribute_source  stofs_3d_pac_redistribute_source.f90 
debug: stofs_3d_pac_redistribute_source.f90
	        $(FC) -g -o stofs_3d_pac_redistribute_source  stofs_3d_pac_redistribute_source.f90 
install: all
	        mkdir build; cp stofs_3d_pac_redistribute_source  build/
clean:
	        rm -f ./*.o ./stofs_3d_pac_redistribute_source;rm -rf ./build

