#!/usr/bin/bash

ROOT=${1-$(pwd)}

if [[ ! -f "$ROOT/naev.6" ]]; then
   echo "Please run from Naikari root directory, or run with update-po.sh [source_root]"
   exit -1
fi

cd $ROOT

set -x

# General file
TMPFILE=$(mktemp)
echo "src/log.h" > "$TMPFILE"
find src/ -name "*.c" -and \( -not -name "shaders.gen.c" \) >> "$TMPFILE"
find dat/ -name "*.lua" >> "$TMPFILE"

cat "$TMPFILE" | sort | tee "$ROOT/po/POTFILES_COMBINED.in" > "$ROOT/po/POTFILES.in"

rm "$TMPFILE" # clean-up

# XML file
find dat/ -maxdepth 1 -name "*.xml" > "$TMPFILE"
find dat/assets -name "*.xml" >> "$TMPFILE"
find dat/outfits -name "*.xml" >> "$TMPFILE"
find dat/ships -name "*.xml" >> "$TMPFILE"

cat "$TMPFILE" | sort | tee -a "$ROOT/po/POTFILES_COMBINED.in" > "$ROOT/po/POTFILES_XML.in"
echo "po/xml.pot" >> "$ROOT/po/POTFILES.in"

rm "$TMPFILE" # clean-up
