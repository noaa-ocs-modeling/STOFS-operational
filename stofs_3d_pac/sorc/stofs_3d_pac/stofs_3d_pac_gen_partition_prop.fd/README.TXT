
README.TXT (3/14/2024)
-----------------------

  In Cactus: /lfs/h1/nos/estofs/noscrub/IT-stofs.v2.1.0/partition_prop_stofs_3d_atl 
      - Here contains a complete setup for program run (including compiled executables and the needed model static files). Users may use this set up to create partition.prop (see details shown in the following Step 2)
      - Please update NCPU_PBS in (2.b) to fit your need. NCPU_PBS is defaulted to be 8640.
      - A sample output for NCPU_PBS=8640 is included, stofs_3d_atl_partition.prop_NCPU_PBS_8640.   
      - The following (1) shows the steps to compile the Fortran codes.


dir_wk=/lfs/h1/nos/estofs/noscrub/IT-stofs.v2.1.0/partition_prop_stofs_3d_atl

(1) Executables for creating fix/stofs_3d_atl_partition.prop

    It needs two executables, metis_prep and gpmetis. See in the following (1.a) and (1.b) for the corresponding source code directories.
    I compiled the following two codes on Cactus today (3/13/2024). The executables are 
        ${dir_wk}/Grid_Scripts/metis_prep, and
        ${dir_wk}/metis-5.1.0/build/Linux-x86_64/programs/gpmetis
    
    (1.a) Compile to create metis_prep 
        cd ${dir_wk}/Grid_Scripts
        ifort -mcmodel=medium  -O2 -CB -g -traceback -o metis_prep metis_prep.f90 
     
        # FYI, executable file: ${dir_wk}/Grid_Scripts/metis_prep

    (1.b) Compile to create gpmetis
        cd ${dir_wk}/metis-5.1.0
        make distclean
        make config cc=cc
        make                    
 
        # FYI, executable file: ${dir_wk}/metis-5.1.0/build/Linux-x86_64/programs/gpmetis

(2) To generate fix/stofs_3d_atl_partition.prop
    
    (2.a) Create the file, graphinfo: this file is an intermediate file that is used in (2.b). It remains the same with varied NCPU_PBS values; hence, it only needs to be created "once" (i.e. don't need to change it if using a different NCPU_PBS).
        cd ${dir_wk}/

        rm -f graphinfo
        ./metis_prep 
 
    (2.b) Create fix/stofs_3d_atl_partition.prop
        cd ${dir_wk}

        # ----------------------- Please update the following number to fit your need!
          let NCPU_PBS=8640
        # -----------------------

       let nproc=${NCPU_PBS}-6       
       echo "NCPU_PBS = ${NCPU_PBS}"

       rm -f graphinfo.part.${nproc}
       ./gpmetis graphinfo ${nproc}  -ufactor=1.01 -seed=15 

       fn_out_partition=stofs_3d_atl_partition.prop_NCPU_PBS_${NCPU_PBS}
       rm -f ${fn_out_partition}
       awk '{print NR,$0}' graphinfo.part.${nproc} > ${fn_out_partition}










