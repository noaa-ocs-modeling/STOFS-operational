Build instruction:
1. cd to the sorc/stofs_3d_pac/ direcotry, e.g., ./dev.stofs.v1.1.0/sorc/stofs_3d_pac

2. make sure that stofs_3d_pac.build is avaiable.

3. to build all executables; the generated executables are copied to ./dev.stofs.v1.1.0/exec/stofs_3d_pac
   ./build_codes.sh   

4. to build one executable, provide their name as parameter, e.g.,
   ./build_codes.sh stofs_2d_glo_tide_fac

5. to clean all executables:
   ./build_codes.sh clean

