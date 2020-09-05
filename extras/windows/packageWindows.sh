#!/bin/bash
# WINDOWS PACKAGING SCRIPT FOR NAIKARI
# Requires NSIS, and python3-pip to be installed
#
# This script should be run after compiling Naikari
# It detects the current environment, and builds the appropriate NSIS installer
# into the root naikari directory.
#

# Checks if argument(s) are valid

if [[ $1 == "--nightly" ]]; then
    echo "Building for nightly release"
    NIGHTLY=true
    # Get Formatted Date
    BUILD_DATE="$(date +%m_%d_%Y)"
elif [[ $1 == "" ]]; then
    echo "No arguments passed, assuming normal release"
    NIGHTLY=false
elif [[ $1 != "--nightly" ]]; then
    echo "Please use argument --nightly if you are building this as a nightly build"
    exit -1
else
    echo "Something went wrong."
    exit -1
fi

# Check if we are running in the right place

if [[ ! -f "naikari.6" ]]; then
    echo "Please run from Naikari root directory."
    exit -1
fi

# Rudementary way of detecting which environment we are packaging.. 
# It works, and it should remain working until msys changes their naming scheme

if [[ $PATH == *"mingw32"* ]]; then
    echo "Detected MinGW32 environment"
    ARCH="32"
elif [[ $PATH == *"mingw64"* ]]; then
    echo "Detected MinGW64 environment"
    ARCH="64"
else
    echo "Welp, I don't know what environment this is... Make sure you are running this in an MSYS2 MinGW environment"
    exit -1
fi

VERSION="$(cat $(pwd)/VERSION)"
BETA=false
# Get version, negative minors mean betas
if [[ -n $(echo "$VERSION" | grep "-") ]]; then
    BASEVER=$(echo "$VERSION" | sed 's/\.-.*//')
    BETAVER=$(echo "$VERSION" | sed 's/.*-//')
    VERSION="$BASEVER.0-beta.$BETAVER"
    BETA=true
else
    echo "could not find VERSION file"
    exit -1
fi

# Download and Install mingw-ldd
echo "Update pip"
pip3 install --upgrade pip

echo "Install mingw-ldd script"
pip3 install mingw-ldd

# Download Inetc
# This is the Plugin that handles downloading NData, this needed to be 
# changed as NSISdl does not support secure downloads

echo "Creating Temp Folder"
mkdir -p ~/temp

echo "Downloading Inetc release"
if wget https://github.com/DigitalMediaServer/NSIS-INetC-plugin/releases/download/v1.0.5.6/INetC.zip -P ~/temp --tries=3; then

    echo "Decompressing Inetc release"
    unzip ~/temp/Inetc.zip -d ~/temp

    # Install Inetc

    echo "Installing Inetc"
    if [[ $ARCH == "32" ]]; then
        cp -r ~/temp/x86-unicode/* /mingw32/share/nsis/Plugins/unicode
        echo "Cleaning up temp folder"
        rm -rf ~/temp
    elif [[ $ARCH == "64" ]]; then
        cp -r ~/temp/x64-unicode/* /mingw64/share/nsis/Plugins/unicode
        echo "Cleaning up temp folder"
        rm -rf ~/temp
    else
        echo "I'm afraid I can't do that Dave..."
        echo "Cleaning up temp folder"
        rm -rf ~/temp
        exit -1
    fi
else
    echo "Something went wrong while downloading Inetc release"
    exit -1
fi

# Move compiled binary to staging folder.

echo "creating staging area"
mkdir -p extras/windows/installer/bin

# Collect DLLs
 
if [[ $ARCH == "32" ]]; then
for fn in `mingw-ldd naikari.exe --dll-lookup-dirs /mingw32/bin | grep -i "mingw32" | cut -f1 -d"/" --complement`; do
    fp="/"$fn
    echo "copying $fp to staging area"
    cp $fp extras/windows/installer/bin
done
elif [[ $ARCH == "64" ]]; then
for fn in `mingw-ldd naikari.exe --dll-lookup-dirs /mingw64/bin | grep -i "mingw64" | cut -f1 -d"/" --complement`; do
    fp="/"$fn
    echo "copying $fp to staging area"
    cp $fp extras/windows/installer/bin
done
else
    echo "Aw, man, I shot Marvin in the face..."
    echo "Something went wrong while looking for DLLs to stage."
    exit -1
fi

echo "copying naikari binary to staging area"
if [[ $NIGHTLY == true ]]; then
cp src/naikari.exe extras/windows/installer/bin/naikari-$VERSION-$BUILD_DATE-win$ARCH.exe
elif [[ $NIGHTLY == false ]]; then
cp src/naikari.exe extras/windows/installer/bin/naikari-$VERSION-win$ARCH.exe
else
    echo "Cannot think of another movie quote."
    echo "Something went wrong while copying binary to staging area."
    exit -1
fi

# Build installer

if [[ $NIGHTLY == true ]]; then
    if [[ $BETA == true ]]; then 
        makensis -DVERSION=$BASEVER.0 -DVERSION_SUFFIX=-beta.$BETAVER-$BUILD_DATE -DARCH=$ARCH -DRELEASE=nightly extras/windows/installer/naikari.nsi
    elif [[ $BETA == false ]]; then 
        makensis -DVERSION=$VERSION -DVERSION_SUFFIX=-$BUILD_DATE -DARCH=$ARCH -DRELEASE=nightly extras/windows/installer/naikari.nsi
    else
        echo "Something went wrong determining if this is a beta or not."
    fi
    

# Move installer to root directory
mv extras/windows/installer/naikari-$VERSION-$BUILD_DATE-win$ARCH.exe naikari-win$ARCH.exe

elif [[ $NIGHTLY == false ]]; then
    if [[ $BETA == true ]]; then 
        makensis -DVERSION=$BASEVER.0 -DVERSION_SUFFIX=-beta.$BETAVER -DARCH=$ARCH -DRELEASE=v$BASEVER.0-beta.$BETAVER extras/windows/installer/naikari.nsi
    elif [[ $BETA == false ]]; then 
        makensis -DVERSION=$VERSION -DVERSION_SUFFIX= -DARCH=$ARCH -DRELEASE=v$VERSION extras/windows/installer/naikari.nsi
    else
        echo "Something went wrong determining if this is a beta or not."
    fi

# Move installer to root directory
mv extras/windows/installer/naikari-$VERSION-win$ARCH.exe naikari-win$ARCH.exe
else
    echo "Cannot think of another movie quote.. again."
    echo "Something went wrong.."
    exit -1
fi

echo "Successfully built Windows Installer for win$ARCH"

# Package zip

if [[ $NIGHTLY == true ]]; then
cd extras/windows/installer/bin
zip ../../../../naikari-win$ARCH.zip *.*
cd ../../../../

elif [[ $NIGHTLY == false ]]; then
cd extras/windows/installer/bin
zip ../../../../naikari-win$ARCH.zip *.*
cd ../../../../

else
    echo "Cannot think of another movie quote.. again."
    echo "Something went wrong.."
    exit -1
fi

echo "Successfully packaged zipped folder for win$ARCH"

echo "Cleaning up staging area"
rm -rf extras/windows/installer/bin
