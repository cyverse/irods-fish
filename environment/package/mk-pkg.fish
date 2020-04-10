#!/usr/bin/fish

set PkgDir (dirname (realpath (status --current-filename)))
set BaseDir (dirname $PkgDir)
set StagingDir /tmp/irods-fish
set FishCfgDir $StagingDir/etc/fish

rm --force --recursive $StagingDir
mkdir --parents $StagingDir

mkdir --parents $FishCfgDir/completions $FishCfgDir/functions
cp $BaseDir/completions/functions/* $BaseDir/functions/* $BaseDir/prompt/* $FishCfgDir/functions/
cp $BaseDir/completions/*.fish $FishCfgDir/completions/

set size (du --summarize --block-size 1 $StagingDir | cut --field 1)

mkdir --parents $StagingDir/DEBIAN
m4 --define m4_SIZE=$size $PkgDir/control.m4 > $StagingDir/DEBIAN/control

dpkg-deb --build $StagingDir /tmp
