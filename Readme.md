![Nightly Release](https://github.com/naikari/naikari/workflows/Nightly%20Release/badge.svg) ![CI](https://github.com/naikari/naikari/workflows/CI/badge.svg)
# NAIKARI README

![Naikari](https://naikari.github.io/images/logo.png)

Naikari is a 2D space trading and combat game, taking inspiration from the [Escape
Velocity series](https://en.wikipedia.org/wiki/Escape_Velocity_(video_game)), among others.

You pilot a space ship from a top-down perspective, and are more or less free
to do what you want. As the genre name implies, you’re able to trade and engage
in combat at will. Beyond that, there’s an ever-growing number of storyline
missions, equipment, and ships; Even the galaxy itself grows larger with each
release. For the literarily-inclined, there are large amounts of lore
accompanying everything from planets to equipment.

## DEPENDENCIES

Naikari's dependencies are intended to be relatively common. In addition to
an OpenGL-capable graphics card and driver, Naikari requires the following:
* SDL 2
* libxml2
* freetype2
* libpng
* OpenAL
* libvorbis
* binutils
* intltool

If you're cross-compiling for Windows, you must install this soft dependency:
* [physfs](https://icculus.org/physfs/), example package name mingw-w64-physfs


### Ubuntu

Install compile-time dependencies on Ubuntu 16.04 (and hopefully later) with:

```
apt-get install build-essential libsdl2-dev libsdl2-image-dev \
libgl1-mesa-dev libxml2-dev libfreetype6-dev libpng-dev libopenal-dev \
libvorbis-dev binutils-dev libiberty-dev autopoint intltool libfontconfig-dev \
python3-pip
pip3 install meson ninja
```

### macOS

Warning: this procedure is inadequate if you want to build a Naev.app that you can share with users of older macOS versions than your own.

Dependencies may be installed using [Homebrew](https://brew.sh):
```
brew install freetype gettext intltool libpng libvorbis luajit meson openal-soft physfs pkg-config sdl2_image suite-sparse
```
Building the latest available code in git is recommended, but to build version 0.8 you can add `sdl2_mixer` (and `autoconf-archive` and `automake` if using Autotools to build).

Meson needs an extra argument to find Homebrew's `openal-soft` package: `--pkg-config-path=/usr/local/opt/openal-soft/lib/pkgconfig`.
If build may fail if `suite-sparse` is installed via Homebrew, citing an undefined reference to `_cs_di_spfree`. A workaround is to pass `--force-fallback-for=SuiteSparse`.
(These arguments may be passed to the initial `meson setup` or applied later using `meson configure`. For 0.8/Autotools, set the `PKG_CONFIG_PATH` environment variable before running `./configure`.)

### Other Linux

See https://github.com/naikari/naikari/wiki/Compiling-on-Linux for
package lists for several distributions.

## COMPILING

Run:

```
bash
meson setup builddir .
cd builddir
meson compile
meson compile naev-gmo  # To make non-English translations available
./naikari.sh
```

If you need special settings you can run `meson configure` in your build
directory to see a list of all available options.

## INSTALLATION

Naikari currently supports `meson install` which will install everything that
is needed.

If you wish to create a .desktop for your desktop environment, logos
from 16x16 to 256x256 can be found in `extras/logos/`.

## WINDOWS

See https://github.com/naikari/naikari/wiki/Compiling-on-Windows for how to compile on windows.

## UPDATING PO FILES

If you are a developer, you may need to update translation files as
text is modified. You can update all translation files with the
following commands:

```
meson compile potfiles # only necessary if files have been added or removed
meson compile naikari-pot
meson compile naikari-update-po
```

Again, you will only ever need to do this if you are a developer.

## CRASHES & PROBLEMS

Please take a look at the [FAQ](https://github.com/naev/naev/wiki/FAQ) before submitting a new
bug report, as it covers a number of common gameplay questions and
common issues.

If Naikari is crashing during gameplay, please file a bug report.

