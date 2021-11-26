#!/bin/bash

# AppImage BUILD SCRIPT FOR NAEV
#
# Written by Jack Greiner (ProjectSynchro on Github: https://github.com/ProjectSynchro/)
#
# For more information, see http://appimage.org/
# Pass in [-d] [-c] (set this for debug builds) [-n] (set this for nightly builds) -s <SOURCEROOT> (Sets location of source) -b <BUILDROOT> (Sets location of build directory)

# Output destination is ${BUILDPATH}/dist

set -e

# Defaults
SOURCEROOT="$(pwd)"
BUILDPATH="$(pwd)/build/appimageBuild"
NIGHTLY="false"
BUILDTYPE="release"

while getopts dcnms:b:o: OPTION "$@"; do
    case $OPTION in
    d)
        set -x
        ;;
    c)
        BUILDTYPE="debug"
        ;;        
    n)
        NIGHTLY="true"
        BUILDTYPE="debug"
        ;;
    s)
        SOURCEROOT="${OPTARG}"
        ;;
    b)
        BUILDPATH="${OPTARG}"
        ;;
    esac
done

BUILD_DATE="$(date +%Y%m%d)"

# Honours the MESON variable set by the environment before setting it manually.

if [ -z "$MESON" ]; then
    MESON="$SOURCEROOT/meson.sh"
fi


# Output configured variables

echo "SOURCE ROOT:        $SOURCEROOT"
echo "BUILD ROOT:         $BUILDPATH"
echo "NIGHTLY:            $NIGHTLY"
echo "BUILDTYPE:          $BUILDTYPE"
echo "MESON WRAPPER PATH: $MESON"

export DESTDIR="$(readlink -mf "$BUILDPATH")/dist/Naikari.AppDir"

# Run build
# Setup AppImage Build Directory
sh "$MESON" setup "$BUILDPATH" "$SOURCEROOT" \
--native-file "$SOURCEROOT/utils/build/linux.ini" \
--buildtype "$BUILDTYPE" \
--force-fallback-for=glpk,SuiteSparse \
-Dnightly="$NIGHTLY" \
-Dprefix="/usr" \
-Db_lto=true \
-Dauto_features=enabled \
-Ddocs_c=disabled \
-Ddocs_lua=disabled

# Compile and Install Naev to DISTDIR
sh "$MESON" install -C "$BUILDPATH"

# Prep dist directory for appimage
# (I hate this but otherwise linuxdeploy fails on systems that generate the desktop file)
cp -f "$SOURCEROOT/io.github.naikari.naikari.desktop" "$DESTDIR/usr/share/applications/"

# Set ARCH of AppImage
export ARCH=$(arch)

# Set VERSION and OUTPUT variables
if [ -f "$SOURCEROOT/dat/VERSION" ]; then
    export VERSION="$(<"$SOURCEROOT/dat/VERSION")"
else
    echo "The VERSION file is missing from $SOURCEROOT."
    exit -1
fi

if [[ "$BUILDTYPE" =~ "debug" ]]; then
    export VERSION="$VERSION+DEBUG.$BUILD_DATE"
fi

SUFFIX="$VERSION-linux-x86-64"

# Make output dir (if it does not exist)
mkdir -p "$BUILDPATH/dist"

export OUTPUT="$BUILDPATH/dist/naikari-$SUFFIX.AppImage"

# Get linuxdeploy's AppImage
linuxdeploy="$BUILDPATH/linuxdeploy-x86_64.AppImage"
if [ ! -f "$linuxdeploy" ]; then
    curl -L -o "$linuxdeploy" https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage
    chmod +x "$linuxdeploy"
fi

# Run linuxdeploy and generate an AppDir, then generate an AppImage

"$linuxdeploy" \
    --appdir "$DESTDIR" \
    --output appimage

# Mark as executable
chmod +x "$OUTPUT"
