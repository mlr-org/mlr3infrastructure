#!/bin/bash
set -euo pipefail

# script for creating a conda environment with all the dependencies needed 
# to run revdepcheck on mlr3

conda create -n revdep -c conda-forge python=3.12
conda activate revdep
conda install -c conda-forge r-base=4.6.0 zlib libuv icu cmake libxml2-devel xz \
  freetype=2.14.3 gmp mpfr udunits2 libhiredis libgit2 libprotobuf rust \
  gdal geos proj sqlite \
  xorg-xorgproto xorg-libx11 xorg-libxext xorg-libxrender \
  libsodium pandoc openjdk \
  glib librsvg imagemagick \
  libarrow-all=25
# glib is listed explicitly even though librsvg/others pull in libglib
# transitively: only the runtime libglib.so gets installed that way, not
# glibconfig.h / headers, which librsvg's rsvg.h needs (glibconfig.h lives
# in lib/glib-2.0/include, separate from the glib.h include dir)

# conda-forge's r-base ships this R with CXX20/CXX20STD left blank in
# Makeconf even though the bundled gcc fully supports -std=c++20; arrow's
# configure takes the blank at face value and refuses to build. Fill it in
# from the CXX17 entries.
sed -i \
  -e "s|^CXX20 = *\$|CXX20 = x86_64-conda-linux-gnu-c++|" \
  -e "s|^CXX20STD = *\$|CXX20STD = -std=gnu++20|" \
  -e "/^CXX20PICFLAGS = *\$/s|.*|CXX20PICFLAGS = -fpic|" \
  "$CONDA_PREFIX/lib/R/etc/Makeconf"
CXX17FLAGS_LINE=$(grep "^CXX17FLAGS = " "$CONDA_PREFIX/lib/R/etc/Makeconf")
sed -i "s|^CXX20FLAGS = .*\$(LTO)\$|CXX20FLAGS = ${CXX17FLAGS_LINE#CXX17FLAGS = }|" \
  "$CONDA_PREFIX/lib/R/etc/Makeconf"

export PKG_CONFIG_PATH="$CONDA_PREFIX/lib/pkgconfig/"
export LD_LIBRARY_PATH="$CONDA_PREFIX/lib:$CONDA_PREFIX/lib/jvm/lib/server:$LD_LIBRARY_PATH"
export PATH="$CONDA_PREFIX/bin:$PATH"

# point R at conda's own openjdk instead of the system JDK: rJava linking
# against the system libjvm.so pulls in the system glibc's private symbols
# via conda's portable-baseline sysroot libpthread/libc, which don't match
# (undefined reference to e.g. __twalk_r@GLIBC_PRIVATE). Using conda's own
# JDK keeps the whole toolchain self-consistent. LD_LIBRARY_PATH above is
# needed too: rJava.so's own link step doesn't bake in an rpath for the
# JVM's lib/server dir, only for $CONDA_PREFIX/lib.
export JAVA_HOME="$CONDA_PREFIX/lib/jvm"
R CMD javareconf

# force sf/terra to link against conda's GDAL/GEOS/PROJ instead of the
# system copies in /usr/lib, whose curl/ssh/openldap/poppler symbol
# versions don't match and break the link step
export GDAL_CONFIG="$CONDA_PREFIX/bin/gdal-config"
export GEOS_CONFIG="$CONDA_PREFIX/bin/geos-config"
export PROJ_LIB="$CONDA_PREFIX/share/proj"

# the arrow R package defaults to downloading a prebuilt libarrow binary
# that requires glibc >= 2.32 (references __libc_single_threaded); this
# host is Ubuntu 20.04 with glibc 2.31, so that binary fails to dyn.load.
# Use conda's own libarrow-all (installed above, matching version) via
# pkg-config instead, which is built consistently with this toolchain.
export ARROW_USE_PKG_CONFIG=true
export LIBARROW_BINARY=false

unset MAKEFLAGS

# install R packages / set up renv
Rscript - <<'EOF'
options("install.opts" = "--without-keep.source")
options("renv.config.pak.enabled" = TRUE)

install.packages("renv")

renv::init(bare = TRUE)
renv::load(".")

# this steps needs a github PAT
renv::install(c(
  "mlr-org/revdepcheck"
))

EOF
