!--------------------------------------------------------------------------
! hsofs_netcdf2shef.f is to compute shef output file in feet from
! adcirc fort.61.nc in MLLW.
!--------------------------------------------------------------------------

      include 'netcdf.inc'

      character*3 area
      character*3 type
      character*3 string_var
      integer i,j,k
      integer ryear,rmonth,rday,rhour,rmin
      integer ncsth, lmn
      integer iout, irow, ihead

      integer iargc, argcount
      character*2048 cmdlinearg, datafile(20)
      character*(*) NAME_TIME, NAME_STATION, NAME_NAMELEN
      character*(*) VAR_STATION, VAR_ZETA
      character*50, allocatable :: station_name(:)
      character*5, allocatable :: station_id(:)
      character*6, allocatable :: wmo_header(:)
      character*5 id
      parameter ( NAME_TIME = 'time' )
      parameter ( NAME_STATION = 'station' )
      parameter ( NAME_NAMELEN = 'namelen' )
      parameter ( VAR_ZETA = 'zeta' )
      parameter ( VAR_STATION = 'station_name' )

      integer ncid, retval
      integer time, station, namelen
      integer time_dimid, station_dimid, namelen_dimid
      integer station_varid, zeta_varid
      integer np
      real, parameter :: M2FT = 3.28084 ! meters to feet
      real, parameter :: FT2M = 0.30480 ! feet to meters
      real*8, allocatable :: zeta(:,:)
      real*8, allocatable :: xy3(:)

      argcount = iargc() ! count up command line options
      if (argcount.gt.0) then
         i=0
         do while (i.lt.argcount)
            i = i + 1
            call getarg(i, cmdlinearg)
            write(6,*) "INFO: processing ",trim(cmdlinearg),"."
            datafile(i)=trim(cmdlinearg)
         end do
       end if

C****** READ AREA FROM CONTROL.TXT, UNIT 5 *******
      read(datafile(1),'(A3)') area
      read(datafile(2),'(A3)') type
      write(6,10) "INFO: processing ", area, type
   10 format(A18,A3,X,A3)

C******* FILL THESE WITH CORRECT PREFERENCE DATE. *******
      read(datafile(3),'(I4,3I2)') ryear, rmonth, rday, rhour
      write(6,11) "INFO: processing ", ryear, rmonth, rday, rhour
   11 format(A18,I10,X,I2,X,I2,X,I2)
      rmin=0

! -------   Open Netcdf file   -------
      retval = nf_open( trim(datafile(4)), nf_nowrite, ncid )
      if ( retval .ne. nf_noerr ) call handle_err(retval)
!-------   Get  station and time dimension, and zeta variable   -------
      retval = nf_inq_dimid( ncid, NAME_TIME, time_dimid )
      if ( retval .ne. nf_noerr ) call handle_err(retval)
      retval = nf_inq_dimid( ncid, NAME_STATION, station_dimid )
      if ( retval .ne. nf_noerr ) call handle_err(retval)
      retval = nf_inq_dimid( ncid, NAME_NAMELEN, namelen_dimid )
      if ( retval .ne. nf_noerr ) call handle_err(retval)
      retval = nf_inq_varid( ncid, VAR_STATION, station_varid )
      if ( retval .ne. nf_noerr ) call handle_err(retval)
      retval = nf_inq_varid( ncid, VAR_ZETA, zeta_varid )
      if ( retval .ne. nf_noerr ) call handle_err(retval)
!-------   Read station and time length  -------
      retval = nf_inq_dimlen ( ncid, time_dimid, time )
      if ( retval .ne. nf_noerr ) call handle_err(retval)
      retval = nf_inq_dimlen ( ncid, station_dimid, station )
      if ( retval .ne. nf_noerr ) call handle_err(retval)
      retval = nf_inq_dimlen ( ncid, namelen_dimid, namelen )
      if ( retval .ne. nf_noerr ) call handle_err(retval)
!-------   Allocate water level   ------
      write(6,12) "INFO: processing ", station, time, namelen
   12 format(A18,X,I5,X,I5,X,I5)
      allocate(zeta(station,time))
      allocate(station_name(station))
      allocate(station_id(station),wmo_header(station))
!-------   Read zeta data and station name -------
      retval = nf_get_var_double( ncid, zeta_varid, zeta )
      if ( retval .ne. nf_noerr ) call handle_err(retval)
      retval = nf_get_var_text( ncid, station_varid, station_name)
      if ( retval .ne. nf_noerr ) call handle_err(retval)
!-------   Extract SHEF ID from station name -------
      write(51,'(A12)')(station_name(i),i=1,station)
      close(51)
       
!------    Read ESTOFS MSL-MLLW datum difference  -------
      open(5,file=trim(datafile(5)))
      read(5,*) np
      write(6,13) "INFO: processing ", np
   13 format(A18,X,I5)
      allocate(xy3(np))
      do i = 1, np
         read(5,*) k, xy3(i)
      end do

!-------   Write   ------
      do j = 1, time
         do i = 1, station
            if ( zeta(i,j) .eq. -99999 ) then
               zeta(i,j) = -9999.d0
            else
C******* Convert meter to feet *********
               if ( type .ne. "swl" ) then
                  zeta(i,j) = ( zeta(i,j) + xy3(i) ) * M2FT ! MLLW
               else
                  zeta(i,j) = zeta(i,j) * M2FT ! MLLW
              end if
            end if
         end do
      end do
     
      ncsth = 1 !239 ! Fei/ZY; 60 ! 60 time step nowcast output
      ihead = 4 ! number of output at header
      irow = 12 ! number of rows
      iout = 1  ! Fei/ZY; 1: every 6 minutes, 5: every 30 minutes
      lmn=5000
      do i = 1, station
         read(51,'(A5,X,A6)') station_id(i),wmo_header(i)
         if ( i .eq. 1 ) then
         if ( type .eq. "cwl" ) then
           write(lmn+i,14)"SXUS02","KWBM",rday,rhour,rmin
           write(lmn+i,15)"TIBEP "
           write(lmn+i,15)":SHEF ENCODED 30 MINUTE WATER LEVEL MODEL 
     &GUIDANCE"
           write(lmn+i,15)":WATER LEVEL VALUES REFERENCED TO MLLW IN 
     &FEET (HMIFR)"
           write(lmn+i,15)":TIME ZONE IS UTC"
           write(lmn+i,15)":WATER LEVEL MODEL GUIDANCE IS FOR COMBINED 
     &WATER LEVELS"
           write(lmn+i,15)":PROVIDED BY NOAA/NOS/OCS/CSDL/CMMB"
         else if ( type .eq. "htp" ) then
           write(lmn+i,14)"SXUS01","KWBM",rday,rhour,rmin
           write(lmn+i,15)"TIBEP "
           write(lmn+i,15)":SHEF ENCODED 30 MINUTE WATER LEVEL MODEL 
     &GUIDANCE"
           write(lmn+i,15)":WATER LEVEL VALUES REFERENCED TO MLLW IN 
     &FEET (HMIFB)"
           write(lmn+i,15)":TIME ZONE IS UTC"
           write(lmn+i,15)":WATER LEVEL MODEL GUIDANCE IS FOR TIDAL 
     &WATER LEVELS"
           write(lmn+i,15)":PROVIDED BY NOAA/NOS/OCS/CSDL/CMMB"
         else 
           write(lmn+i,14)"SXUS03","KWBM",rday,rhour,rmin
           write(lmn+i,15)"TIBEP "
           write(lmn+i,15)":SHEF ENCODED 30 MINUTE WATER LEVEL MODEL 
     &GUIDANCE"
           write(lmn+i,15)":WATER LEVEL VALUES REFERENCED TO MLLW IN 
     &FEET (HMIFD)"
           write(lmn+i,15)":TIME ZONE IS UTC"
           write(lmn+i,15)":WATER LEVEL MODEL GUIDANCE IS FOR SUB-TIDAL 
     &WATER LEVELS"
           write(lmn+i,15)":PROVIDED BY NOAA/NOS/OCS/CSDL/CMMB"
         end if
         end if

         if ( type .eq. "cwl" ) then
            write(lmn+i,16)station_id(i),ryear,rmonth,rday,
     &      rhour,rmin,rmonth,rday,rhour,rmin,6*iout,
     &      (zeta(i,j),j=ncsth,ncsth+ihead*iout,iout)
         else if ( type .eq. "htp" ) then
            write(lmn+i,17)station_id(i),ryear,rmonth,rday,
     &      rhour,rmin,rmonth,rday,rhour,rmin,6*iout,
     &      (zeta(i,j),j=ncsth,ncsth+ihead*iout,iout)
         else
            write(lmn+i,18)station_id(i),ryear,rmonth,rday,
     &      rhour,rmin,rmonth,rday,rhour,rmin,6*iout,
     &      (zeta(i,j),j=ncsth,ncsth+ihead*iout,iout)
         end if

         do k = 1, int((time-(ncsth+ihead*iout))/(irow*iout))
            write(string_var,'(I3)') k
            write(lmn+i,19)adjustl(string_var),
     &      (zeta(i,j),j=ncsth+ihead*iout+irow*iout*(k-1)+iout,
     &         ncsth+ihead*iout+irow*iout*(k-1)+irow*iout,iout)
         end do

         write(string_var,'(I3)') k
         write(lmn+i,20)adjustl(string_var),
     &   (zeta(i,j),j=ncsth+ihead*iout+irow*iout*(k-1)+iout,
C Fei/ZY     &               ncsth+ihead*iout+irow*iout*(k-1)+8*iout,iout)
C Fei/ZY: STOFS-3D-Atl: (720-239)/5 - 5 == 92  ;   mod(91, 12)  == 8;
C Fei/ZY: !12 pnts per line;
     &               ncsth+ihead*iout+irow*iout*(k-1)+8*iout,iout)


   14    format(A6,X,A4,X,I2.2I2.2I2.2)
   15    format(A)
   16    format(".E",X,A5,X,I4,2I2.2,X,"Z",X,"DH",2I2.2,"/DC",4I2.2,
     &          "/HMIFR","/DIN",I2.2,"/",X,4(F8.2,"/",X),F8.2)
   17    format(".E",X,A5,X,I4,2I2.2,X,"Z",X,"DH",2I2.2,"/DC",4I2.2,
     &          "/HMIFB","/DIN",I2.2,"/",X,4(F8.2,"/",X),F8.2)
   18    format(".E",X,A5,X,I4,2I2.2,X,"Z",X,"DH",2I2.2,"/DC",4I2.2,
     &          "/HMIFD","/DIN",I2.2,"/",X,4(F8.2,"/",X),F8.2)
   19    format(".E",A,X,11(F8.2,"/",X),F8.2)

C Yuji   20    format(".E",A,X,7(F8.2,"/",X),F8.2)
C ZY:
   20    format(".E",A,X,7(F8.2,"/",X),F8.2)

         end do

      stop
      end

C SUBROUTINE ERROR HANDLE
      subroutine handle_err(errcode)
      implicit none
      include 'netcdf.inc'
      integer errcode

      print *, 'Error: ', nf_strerror(errcode)
      stop 2
      end

