!--------------------------------------------------------------------------
! hsofs_netcdf2grib.f is to compute grib2 output file in NAVD88 from
! both adcirc fort.63.nc and maxele.63.nc files in MSL.
!--------------------------------------------------------------------------

      include 'netcdf.inc'
      
      PARAMETER(NGRIBM=67216400)
      CHARACTER*3     AREA
      CHARACTER*3     TYPE
      CHARACTER*1     CGRIB(NGRIBM)
      INTEGER         LCGRIB
      INTEGER         I,J,K,L,M,N,NX,NY,NXNY
      INTEGER         IMXB(3),JMXB(3)
      INTEGER         RYEAR,RMONTH,RDAY,RHOUR,RMIN,RSEC
      INTEGER         IFCSTHR, LMN
      REAL, ALLOCATABLE :: HA(:,:)

      integer ijk
      integer iargc, argcount
      character*2048 cmdlinearg, datafile(20)
      character*(*) TIME_NAME, NODE_NAME, ZETA_NAME
      parameter ( TIME_NAME = 'time' )
      parameter ( NODE_NAME = 'node' )
      parameter ( ZETA_NAME = 'zeta' )

      integer n1, n2, n3
      integer ncid, retval
      integer ymdh
      integer time, node
      integer ne, nn
      integer time_dimid, node_dimid
      integer zeta_varid
      real    xy1, xy2
      real    wlnew  
      integer, allocatable :: badnode(:)
      integer, allocatable :: nn1(:,:)
      real*8, allocatable :: wl(:), wlndfd(:)
      real*8, allocatable :: zwl(:,:), zeta(:,:)
      real, allocatable :: fact1(:,:)

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
      read(datafile(1),'(A3)') AREA
      read(datafile(2),'(A3)') TYPE
      write(6,1000) "INFO: processing ", AREA, TYPE
 1000 format(A18,A3,X,A3)

C******* FILL THESE WITH CORRECT PREFERENCE DATE. *******
      read(datafile(3),'(I4,3I2)') RYEAR, RMONTH, RDAY, RHOUR
      write(6,1001) "INFO: processing ", RYEAR, RMONTH, RDAY, RHOUR
 1001 format(A18,I10,X,I2,X,I2,X,I2)
      RMIN=0
      RSEC=0

C***** CALL ESTOFS MAP PROJECTION MASK *******
      open(5,file=trim(datafile(4)))
      read(5,*) NXNY, NX, NY
      write(6,1002) "INFO: processing ", NXNY, NX, NY
 1002 format(A18,3I10)
      allocate(nn1(NXNY,3))
      allocate(fact1(NXNY,3))
      allocate(badnode(NXNY))
      allocate(wlndfd(NXNY))
      ALLOCATE(HA(NX,NY))

      do i = 1, NXNY
        read(5,*)ijk,n1,n2,n3,fact1(i,1),fact1(i,2),fact1(i,3)       
        nn1(i,1) = abs(n1)
        nn1(i,2) = abs(n2)
        nn1(i,3) = abs(n3)
        if ( nn1(i,1) .ne. n1) then
          badnode(i) = i
        endif
      end do

! -------   Open Netcdf file   -------
      retval = nf_open( trim(datafile(5)), nf_nowrite, ncid )
      if ( retval .ne. nf_noerr ) call handle_err(retval)
!-------   Get  node and time dimension, and zeta variable   -------
      retval = nf_inq_dimid( ncid, TIME_NAME, time_dimid )
      if ( retval .ne. nf_noerr ) call handle_err(retval)
      retval = nf_inq_dimid( ncid, NODE_NAME, node_dimid )
      if ( retval .ne. nf_noerr ) call handle_err(retval)
      retval = nf_inq_varid( ncid, ZETA_NAME, zeta_varid )
      if ( retval .ne. nf_noerr ) call handle_err(retval)
!-------   Read node and time length  -------
      retval = nf_inq_dimlen ( ncid, time_dimid, time )
      if ( retval .ne. nf_noerr ) call handle_err(retval)
      retval = nf_inq_dimlen ( ncid, node_dimid, node )
      if ( retval .ne. nf_noerr ) call handle_err(retval)
!-------   Allocate water level   ------
      write(6,1002) "INFO: processing ", node, time
      allocate(zeta(node,time))
      allocate(zwl(time,node))
      allocate(wl(node))
!-------   Read zeta data  -------
      retval = nf_get_var_double( ncid, zeta_varid, zeta )
      if ( retval .ne. nf_noerr ) call handle_err(retval)
!-------   Transform allary   ------
      k = 0
      do j = 1, time
         k = k + 1
         do i = 1, node
            zwl(k,i) = zeta(i,j)
         end do
      end do
      
      read(datafile(6),'(I4)') LMN
      write(6,1003) "INFO: processing fort.", LMN
 1003 format(A23,I4)
    
C===================
      do N = 1, time ! (6 hr nowcast + 120 hr forecast) 
C===================
       
C****** TWO to ONE DIMENSION and MSL-NAVD88 Conversion  *******
        do i = 1, node
           wl(i) = zwl(N,i)
        end do
                  
C****** INTERPOLATE ESTOFS NATIVE WL INTO NDFD GRID *******
        do i = 1, NXNY
          wlnew=0
          do j = 1, 3
C****** CHANGE DRY ELEMENT -99999 TO 9999 ********
            if ( wl(nn1(i,j)) == -99999 ) then
              wlnew = 9999
              exit
            else
              wlnew = wlnew + fact1(i,j) * wl(nn1(i,j)) 
            end if
          end do
          wlndfd(i) = wlnew
          if ( i == badnode(i) ) wlndfd(i) = 9999
        end do
        
C****** ONE TO TWO DIMENSION  ********
        do j = 1, NY; do i = 1, NX
           k=(j-1)*NX+i
           HA(i,j)=wlndfd(k)
        end do; end do
        
C SET IFCSTHR TO THE CURRENT HOUR (THROUGH THE LOOP)
C {ZY
C        if ( N .ge. 6 ) then ! -5 hour Nowcast + 180 Hr Forecast;
C           IFCSTHR=N-6  ! Yuji original
         
         if ( N .ge. 24 ) then
            IFCSTHR=N-24
C ZY}
           CALL MKGRIB(CGRIB,LCGRIB,RYEAR,RMONTH,RDAY,RHOUR,RMIN,
     1                 RSEC,HA,NX,NY,AREA,TYPE,NXNY,IFCSTHR,LMN)
           WRITE(IFCSTHR+LMN) (CGRIB(K),K=1,LCGRIB)
        end if
C===========
      end do
C===========
      END

C LCGRIB WILL EVENTUALLY BE THE LENGTH OF THE MESSAGE (AS OPPOSED TO NGRIBM
C WHICH IS THE ALLOCATED SPACE FOR THE MESSAGE.  LCGRIB << NGRIBM.
      SUBROUTINE MKGRIB(CGRIB,LCGRIB,RYEAR,RMONTH,RDAY,RHOUR,RMIN,RSEC,
     1                  HA,NX,NY,AREA,TYPE,NXNY,IFCSTHR,LMN)
      PARAMETER(NGRIBM=67216400)
      PARAMETER(NGDSTMPL=22,IPDSTMPLEN=22,IDRSTMPLEN=22)
      CHARACTER*1     CGRIB(NGRIBM)
      REAL            HA(NX,NY)
      REAL            FLD(NXNY)
      INTEGER         NX,NY,NXNY
      CHARACTER*3     AREA
      CHARACTER*3     TYPE
      INTEGER         LMN
      INTEGER         LSEC0(2)
      INTEGER         LSEC1(13)
      INTEGER         IERR
      INTEGER         LCGRIB
      INTEGER         RYEAR,RMONTH,RDAY,RHOUR,RMIN,RSEC
      CHARACTER*1     CSEC2(1)
      INTEGER         LCSEC2
      INTEGER         IGDS(5)
      INTEGER         IGDSTMPL(NGDSTMPL)
      INTEGER         IDEFLIST(1)
      INTEGER         IDEFNUM
      REAL            COORDLIST(1)
      INTEGER         NUMCOORD
      INTEGER         IPDSNUM
      INTEGER         IPDSTMPL(IPDSTMPLEN)
      INTEGER         IFCSTHR
      INTEGER         IDRSNUM
      INTEGER         IDRSTMPL(IDRSTMPLEN)
      INTEGER         NGRDPTS
      INTEGER         IBMAP
      LOGICAL*1       BMAP(1)
      INTEGER         DSF
      INTEGER         ITEMP

C 10 = OCEANOGRAPHIC PRODUCT, 2 = EDITION NUMBER (GRIB2)
      LSEC0(1) = 10
      LSEC0(2) = 2
C 7 = NCEP, 14 = MDL, 4 VERSION, 1 = VERSION OF THE LOCAL TABLES.
      LSEC1(1) = 7 
      LSEC1(2) = 4
      LSEC1(3) = 3
      LSEC1(4) = 1
C 1 = START OF FORECAST, RYEAR, RMONTH, RDAY, RHOUR, RMIN, RSEC
      LSEC1(5) = 1
      LSEC1(6) = RYEAR
      LSEC1(7) = RMONTH
      LSEC1(8) = RDAY
      LSEC1(9) = RHOUR
      LSEC1(10) = RMIN
      LSEC1(11) = RSEC
C 1 = OPERATIONAL TEST PRODUCT (0 WOULD BE OPERATIONAL)
      LSEC1(12) = 1
C 1 = FORECAST PRODUCTS
      LSEC1(13) = 1
      CALL GRIBCREATE(CGRIB,NGRIBM,LSEC0,LSEC1,IERR)
C CHECK THE RESULTS OF IERR.

      LCSEC2 = 0
      CALL ADDLOCAL(CGRIB,NGRIBM,CSEC2,LCSEC2,IERR)
C CHECK THE RESULTS OF IERR.

C 0 = USING TEMPLATES, GRID SPECIFIED IN 3.1
      IGDS(1) = 0
      IGDS(2) = NX * NY
C 0 = MEANS NO IDEFLIST, 0 MEANS NO APPENDED LIST
      IGDS(3) = 0
      IGDS(4) = 0
C 30 = LAMBERT, 20 = POLAR STEREOGRAPHIC, 10 = MERCATOR 
      IF(AREA=='con') THEN
        IGDS(5) = 30
      ELSE IF(AREA=='ala') THEN
        IGDS(5) = 20
      ELSE 
        IGDS(5) = 10
      END IF
      IGDSTMPL(1) = 1
      IGDSTMPL(2) = 0
      IGDSTMPL(3) = 6371200
      IGDSTMPL(4) = 0
      IGDSTMPL(5) = 0
      IGDSTMPL(6) = 0
      IGDSTMPL(7) = 0
      IGDSTMPL(8) = NX
      IGDSTMPL(9) = NY
      IF(AREA=='con') THEN
        IGDSTMPL(10) = 20191999
        IGDSTMPL(11) = 238445999
      ELSE IF(AREA=='ala') THEN
        IGDSTMPL(10) = 40530101
        IGDSTMPL(11) = 181429000
      ELSE IF(AREA=='pue') THEN
        IGDSTMPL(10) = 16977485
        IGDSTMPL(11) = 291972167
      ELSE IF(AREA=='haw') THEN
        IGDSTMPL(10) = 18072699
        IGDSTMPL(11) = 198474999
      ELSE IF(AREA=='gua') THEN
        IGDSTMPL(10) = 12349884
        IGDSTMPL(11) = 143686538
      ELSE IF(AREA=='nor') THEN
        IGDSTMPL(10) = -25000000
        IGDSTMPL(11) = 110000000
      END IF
C RESOLUTION FLAG IS 0.
      IGDSTMPL(12) = 0
      IF(AREA=='con') THEN
        IGDSTMPL(13) = 25000000
        IGDSTMPL(14) = 265000000
        IGDSTMPL(15) = 2539703 ! NDFD 2.5 km grid
        IGDSTMPL(16) = 2539703 ! NDFD 2.5 km grid
        IGDSTMPL(17) = 0
        IGDSTMPL(18) = 64
        IGDSTMPL(19) = 25000000
        IGDSTMPL(20) = 25000000
        IGDSTMPL(21) = -90000000
        IGDSTMPL(22) = 0
      ELSE IF(AREA=='ala') THEN
        IGDSTMPL(13) = 60000000
        IGDSTMPL(14) = 210000000
        IGDSTMPL(15) = 5953125
        IGDSTMPL(16) = 5953125
        IGDSTMPL(17) = 0
        IGDSTMPL(18) = 64
      ELSE IF(AREA=='pue') THEN
        IGDSTMPL(13) = 20000000
        IGDSTMPL(14) = 19544499
        IGDSTMPL(15) = 296015600
        IGDSTMPL(16) = 64
        IGDSTMPL(17) = 0
        IGDSTMPL(18) = 1250000
        IGDSTMPL(19) = 1250000
      ELSE IF(AREA=='haw') THEN
        IGDSTMPL(13) = 20000000
        IGDSTMPL(14) = 23077799
        IGDSTMPL(15) = 206130999
        IGDSTMPL(16) = 64
        IGDSTMPL(17) = 0
        IGDSTMPL(18) = 2500000
        IGDSTMPL(19) = 2500000
      ELSE IF(AREA=='gua') THEN
        IGDSTMPL(13) = 20000000
        IGDSTMPL(14) = 16794399
        IGDSTMPL(15) = 148280000
        IGDSTMPL(16) = 64
        IGDSTMPL(17) = 0
        IGDSTMPL(18) = 2500000
        IGDSTMPL(19) = 2500000
      ELSE IF(AREA=='nor') THEN
        IGDSTMPL(13) = 20000000
        IGDSTMPL(14) = 60643999
        IGDSTMPL(15) = 250871000
        IGDSTMPL(16) = 64
        IGDSTMPL(17) = 0
        IGDSTMPL(18) = 10000000
        IGDSTMPL(19) = 10000000
      END IF
      IDEFNUM = 0
      CALL ADDGRID(CGRIB,NGRIBM,IGDS,IGDSTMPL,NGDSTMPL,IDEFLIST,
     1             IDEFNUM,IERR)
C CHECK THE RESULTS OF IERR.

C 0 = FORECAST AT A HORIZONTAL LEVEL AT A POINT IN TIME
      IPDSNUM = 0
      IPDSTMPL(1) = 3
      IF (TYPE=='cwl') THEN
        IPDSTMPL(2) = 250
      ELSE IF (TYPE=='htp') THEN
        IPDSTMPL(2) = 194
      ELSE
        IPDSTMPL(2) = 193
      END IF
c 2 = FORECAST
      IPDSTMPL(3) = 2
      IPDSTMPL(4) = 0
      IF(LMN==3000) THEN
        IPDSTMPL(5) = 14 
      ELSE IF(LMN==4000) THEN
        IPDSTMPL(5) = 17 
      ELSE IF(LMN==5000) THEN
        IPDSTMPL(5) = 14 
      ELSE IF(LMN==6000) THEN
        IPDSTMPL(5) = 17 
      ELSE IF(LMN==7000) THEN
        IPDSTMPL(5) = 17 
      ELSE IF(LMN==8000) THEN
        IPDSTMPL(5) = 20 
      ELSE IF(LMN==9000) THEN
        IPDSTMPL(5) = 20 
      END IF
      IPDSTMPL(6) = 0
      IPDSTMPL(6) = 0
      IPDSTMPL(7) = 0
      IPDSTMPL(8) = 1
      IPDSTMPL(9) = IFCSTHR
c 1 = GROUND OR WATER SURFACE
      IPDSTMPL(10) = 1
      IPDSTMPL(11) = 0
      IPDSTMPL(12) = 0
C -1 is all 1's if we are dealing with signed integers.
C 13, and 14 only need 1 byte of all 1's (missing), so could use 255
      IPDSTMPL(13) = -1
      IPDSTMPL(14) = 0
      IPDSTMPL(15) = 0
      NUMCOORD = 0
      NGRDPTS = NX * NY
      IDRSNUM = 2
C REFERENCE VALUE IS SET TO 9999 FOR
      IDRSTMPL(1) = 9999
      IDRSTMPL(2) = 0
C 5 = DECIMAL SCALE FACTOR
      DSF =5
      IDRSTMPL(3) = DSF
      IDRSTMPL(4) = 9999
C 0 = FLOATING POINT (ORIGINAL DATA WAS A FLOATING POINT NUMBER)
      IDRSTMPL(5) = 0
      IDRSTMPL(6) = 9999
C 1 = MISSING VALUE MANAGEMENT (PRIMARY ONLY)
      IDRSTMPL(7) = 1
      call mkieee(9999.,IDRSTMPL(8),1)
      call mkieee(9999.,IDRSTMPL(9),1)
      IDRSTMPL(10) = 9999
      IDRSTMPL(11) = 9999
      IDRSTMPL(12) = 9999
      IDRSTMPL(13) = 9999
      IDRSTMPL(14) = 9999
      IDRSTMPL(15) = 9999
      IDRSTMPL(16) = 9999
       
C LOOP THROUGH THE DATA.
      DO 150 J=1,NY
        DO 140 I=1,NX
            ITEMP = HA(I,J) * 10**DSF + 0.5  
            FLD(I + (J - 1) * NX) = ITEMP / (10**DSF + 0.0)
 140    CONTINUE
 150  CONTINUE
      
C NO BIT MAP APPLIES FOR THE DATA.
      IBMAP = 255
      CALL ADDFIELD(CGRIB,NGRIBM,IPDSNUM,IPDSTMPL,IPDSTMPLEN,
     1              COORDLIST,NUMCOORD,IDRSNUM,IDRSTMPL,
     1              IDRSTMPLEN,FLD,NGRDPTS,IBMAP,BMAP,IERR)
C CHECK THE RESULTS OF IERR.

C RENAME LCGRIB TO LENGRIB
C RENAME NGRIBM TO LCGRIB
      CALL GRIBEND(CGRIB,NGRIBM,LCGRIB,IERR)
C CHECK THE RESULTS OF IERR.
      RETURN
      END

C SUBROUTINE ERROR HANDLE
      subroutine handle_err(errcode)
      implicit none
      include 'netcdf.inc'
      integer errcode

      print *, 'Error: ', nf_strerror(errcode)
      stop 2
      end

