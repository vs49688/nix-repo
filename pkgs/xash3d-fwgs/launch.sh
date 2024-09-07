#!/usr/bin/env bash

##
# NixOS xash3d-fwgs launcher script, based off
# https://github.com/FWGS/xash3d-fwgs/blob/master/scripts/flatpak/run.sh
##

set -e

function die() {
    echo "$@"
    exit 1
}

export XASH3D_RODIR="@out@/lib/xash3d"
echo "XASH3D_RODIR is $XASH3D_RODIR"

export LD_LIBRARY_PATH="$XASH3D_RODIR:$LD_LIBRARY_PATH"

export XASH3D_EXTRAS_PAK1="@out@/share/xash3d/valve/extras.pk3"
echo "XASH3D_EXTRAS_PAK1 is $XASH3D_EXTRAS_PAK1"

# https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html
# $XDG_DATA_HOME defines the base directory relative to which user-specific data files should be stored.
# If $XDG_DATA_HOME is either not set or empty, a default equal to $HOME/.local/share should be used.
if [[ -z "$XDG_DATA_HOME" ]]; then
    export XDG_DATA_HOME="$HOME/.local/share"
fi

if [[ -z "$XASH3D_BASEDIR" ]]; then
    export XASH3D_BASEDIR="$XDG_DATA_HOME/xash3d-fwgs/"
fi

mkdir -p "$XASH3D_BASEDIR"
cd "$XASH3D_BASEDIR" || die "Can't cd into $XASH3D_BASEDIR"
echo "XASH3D_BASEDIR is $XASH3D_BASEDIR"

exec "@out@/bin/.xash3d-wrapped" "$@"
