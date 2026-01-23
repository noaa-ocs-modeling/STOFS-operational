SHELL=/bin/sh
#STOFS2D_GLO init makefile

SUBDIRS = \
	stofs_2d_glo_anomaly.fd \
	stofs_2d_glo_tide_fac.fd \
	stofs_2d_glo_netcdf2grib2.fd \
	stofs_2d_glo_netcdf2shef.fd 

all: $(SUBDIRS)
	for dir in $(SUBDIRS); do \
	   ( cd $$dir; echo "Making $@ in `pwd`" ; make ); \
	done

debug: $(SUBDIRS)
	for dir in $(SUBDIRS); do \
	   ( cd $$dir; echo "Making $@ in `pwd`" ; \
	   make DEBUG=full) ; \
	done

clean: $(SUBDIRS)
	for dir in $(SUBDIRS); do \
	   ( cd $$dir; echo "Making $@ in `pwd`" ; \
	   make $@) ; \
	done

install: $(SUBDIRS)
	for dir in $(SUBDIRS); do \
	   ( cd $$dir; echo "Making $@ in `pwd`" ; \
	   make $@) ; \
	done

test: $(SUBDIRS)
	for dir in $(SUBDIRS); do \
	   ( cd $$dir; echo "Making $@ in `pwd`" ; \
	   make $@) ; \
	done
