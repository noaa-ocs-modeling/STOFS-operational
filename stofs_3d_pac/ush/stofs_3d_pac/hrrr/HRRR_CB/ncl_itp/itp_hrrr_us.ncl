load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"

begin

  srcFileName = "../HRRR/hrrr_2023050400.nc"
  dstFileName = "itpgrid_xy.nc"
  sfile = addfile(srcFileName,"r")
  dfile = addfile(dstFileName,"r")

  var=sfile->spfh(0,:,:)
  src_lon2d=sfile->lon
  src_lat2d=sfile->lat
  dst_lon2d=dfile->LON
  dst_lat2d=dfile->LAT

; Force to >180
; src_lon2d=where(src_lon2d0.lt.0,src_lon2d0+360.,src_lon2d0)

; Option
  Opt                = True

  Opt@WgtFileName    = "weight_hrrr_us.nc"

  Opt@SrcGridLat     = src_lat2d     ; source grid
  Opt@SrcGridLon     = src_lon2d
  Opt@DstGridLat     = dst_lat2d     ; destination grid
  Opt@DstGridLon     = dst_lon2d

  Opt@SrcRegional    = True          ; Necessary if grids
  Opt@DstRegional    = True          ; are regional

  Opt@InterpMethod   = "bilinear"    ; "patch", "conserve"

  Opt@ForceOverwrite = True          ; Optional, but recommended.
  Opt@PrintTimings   = True          ; Optional.
  Opt@Debug          = True          ; Optional

  var_regrid = ESMF_regrid(var,Opt)      ; Do the regridding

end
