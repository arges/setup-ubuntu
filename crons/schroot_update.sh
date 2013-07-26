#!/bin/bash
# Credit: https://wiki.ubuntu.com/SecurityTeam/BuildEnvironment/
# This will keep yer schroots regular
for d in `schroot -l | grep -- '-source$'`
do
        echo "Updating '$d'"
        schroot -q -c $d -u root -- sh -c 'apt-get -qq update && apt-get -qy dist-upgrade && apt-get clean'
        echo ""
done

