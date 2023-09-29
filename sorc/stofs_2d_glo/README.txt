Build instruction:
1. cd to the /sorc/stofs_2d_glo/ direcotry
2. to build all executables:
   ./build_codes.sh   
3. to build all executables with debug:
   ./build_codes.sh debug  
4. to build one executable, provide their name as parameter:
   ./build_codes.sh stofs_2d_glo_tide_fac
   NOTE: if you create stofs_padcirc, the executables are created under work direcotry
5. to build one executable with debug options, provide their name as parameter and debug:
   ./build_codes.sh stofs_2d_glo_tide_fac debug
6. to clean all executables:
   ./build_codes.sh clean
