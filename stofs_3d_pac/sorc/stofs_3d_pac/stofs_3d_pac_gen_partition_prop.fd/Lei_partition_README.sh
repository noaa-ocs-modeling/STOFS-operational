#!/bin/sh

dir_wk=.
        cd ${dir_wk}

        # ----------------------- Please update the following number to fit your need!
        #  let NCPU_PBS=4920
          let NCPU_PBS=3960
        # -----------------------

       let nproc=${NCPU_PBS}-8      
       echo "NCPU_PBS = ${NCPU_PBS}"

       rm -f graphinfo.part.${nproc}
       ./gpmetis graphinfo ${nproc}  -ufactor=1.01 -seed=15

       fn_out_partition=stofs_3d_pac_partition.prop_NCPU_PBS_${NCPU_PBS}
       rm -f ${fn_out_partition}
       awk '{print NR,$0}' graphinfo.part.${nproc} > ${fn_out_partition}

