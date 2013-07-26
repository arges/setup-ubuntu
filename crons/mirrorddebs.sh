#!/bin/bash

export GNUPGHOME=/srv/mirrorkeyring
arch=i386,amd64
section=main
release=lucid,lucid-security,lucid-updates,precise,precise-security,precise-updates,quantal,quantal-security,quantal-updates,raring,raring-security,raring-updates
server=ddebs.ubuntu.com
inPath=/
proto=http
outPath=/srv/ddebs

debmirror       -a $arch --no-source -s $section -h $server \
                -d $release -r $inPath --progress \
                -e $proto --nocleanup $outPath

date >> /srv/last_ddeb_mirror_run

