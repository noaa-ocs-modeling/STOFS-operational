Build instruction:
1. cd to the /sorc/stofs_2d_glo/ direcotry
2. make sure that stofs_2d_glo_build is avaiable.
3. to build all executables:
   ./build_codes.sh   
   Note: The exectable, stofs_2d_glo_adcprep, uses the exactly same source codes and make file as stofs_2d_glo_padcirc, 
   thus we put one source code directory, stofs_2d_glo_padcirc.fd, to aviod the duplication and you can make both stofs_2d_glo_adcprep and stofs_2d_glo_padcirc from stofs_2d_glo_padcirc.fd.
4. to build all executables with DEBUG=full options:
   ./build_codes.sh debug 
5. to build one executable, provide their name as parameter:
   ./build_codes.sh stofs_2d_glo_tide_fac
   NOTE: if you create stofs_adcprep and stofs_padcirc, the executables are created under work direcotry
6. to build one executable with DEBUG=full options, provide their name as parameter and debug:
   ./build_codes.sh stofs_2d_glo_tide_fac debug
7. to clean all executables:
   ./build_codes.sh clean
