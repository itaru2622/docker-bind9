#!/bin/bash

# phase1) copy files from srcDir to zoneDir for easy ops
files=(Makefile README.md)
for f in "${files[@]}"
do
   if ! [[ -e ${zoneDir}/${f} ]]; then
      cp -p ${srcDir}/${f} ${zoneDir}/
      echo "copy ${f} from ${srcDir}"
   fi
done

# phase2) start daemon according to zoneDir status
echo "starting daemon..."

if ! [[ -e ${zoneDir}/named.conf ]]; then
   make start -C ${zoneDir}
else
   make startDaemon -C ${zoneDir}
fi
