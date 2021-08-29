#!/bin/bash

"@source_root@/meson.sh" compile -C "@build_root@" naikari-gmo
for mo_path in "@build_root@"/po/*.gmo; do
    mo_name="$(basename "$mo_path")"
    lang=${mo_name%.gmo}
    mkdir -p "@build_root@"/dat/gettext/$lang/LC_MESSAGES
    cp -v "$mo_path" "@build_root@"/dat/gettext/$lang/LC_MESSAGES/naikari.mo
done
grep -q '%<PRI' "@build_root@"/po/*.gmo && echo "***WARNING: Naikari can't translate 'sysdep' strings like %<PRIu64>. Try %.0f?"

wrapper() {
   if type "gdb" > /dev/null; then
      gdb -x "@source_root@/.gdbinit" --args "$@"
   else
      "$@"
   fi
}

wrapper "@naev_bin@" -d "@source_root@/dat" -d "@source_root@/artwork" -d "@build_root@/dat" -d "@source_root@" "$@"
