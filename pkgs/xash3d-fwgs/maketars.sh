#!/usr/bin/env bash

##
# Helper script to create gamedir tars.
##

for gamedir in valve valve_hd bshift bshift_hd gearbox gearbox_hd tfc dmc ricochet; do
	fulldir="$HOME/.steam/steam/steamapps/common/Half-Life/${gamedir}"

	echo $gamedir
	tar \
		-C "$HOME/.steam/steam/steamapps/common/Half-Life" \
		--owner=0 --group=0 --numeric-owner \
		--mtime='1970-01-01 00:00Z' --sort=name \
		--pax-option=exthdr.name=%d/PaxHeaders/%f,delete=atime,delete=ctime \
		--exclude='**/steam_autocloud.vdf' --exclude=SAVE \
		--exclude=dlls --exclude=cl_dlls \
		-cf "${gamedir}.tar" "$gamedir"
done
