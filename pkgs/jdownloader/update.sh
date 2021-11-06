#!/usr/bin/env nix-shell
#!nix-shell -i bash -p subversion gnugrep nix-prefetch-svn

set -euo pipefail

prefetch() {
	nix-prefetch-svn "$1" "$2" | grep -E '^[a-z0-9]{52}$' | head -1
}

ROOT="$(dirname "$(readlink -f "$0")")"
if [[ ! "$(basename $ROOT)" == "jdownloader" || ! -f "$ROOT/default.nix" ]]; then
    echo "ERROR: Not in the jdownloader folder"
    exit 1
fi

AWU_REV=$(svn info --show-item=revision svn://svn.appwork.org/utils)
echo "INFO: AppWorkUtils revision is $AWU_REV"

JD2_REV=$(svn info --show-item=revision svn://svn.jdownloader.org/jdownloader)
echo "INFO: JDownloader2 revision is $JD2_REV"

APPWORK_HASH=$(prefetch svn://svn.appwork.org/utils "$AWU_REV")
echo "INFO: AppWorkUtils SHA256 is $APPWORK_HASH"

JDOWNLOADER_HASH=$(prefetch svn://svn.jdownloader.org/jdownloader/trunk "$JD2_REV")
echo "INFO: JDownloader2 SHA256 is $JDOWNLOADER_HASH"

JDBROWSER_HASH=$(prefetch svn://svn.jdownloader.org/jdownloader/browser "$JD2_REV")
echo "INFO: JDBrowser SHA256 is $JDBROWSER_HASH"

MYJDOWNLOADER_HASH=$(prefetch svn://svn.jdownloader.org/jdownloader/MyJDownloaderClient "$JD2_REV")
echo "INFO: MyJDownloader SHA256 is $MYJDOWNLOADER_HASH"

sed -i -E \
	-e "s/jdRevision\s*=.*$/jdRevision = \"${JD2_REV}\";/g" \
    -e "s/appWorkRevision\s*=.*$/appWorkRevision = \"${AWU_REV}\";/g" \
	-e "s/appWorkHash\s*=.*$/appWorkHash = \"${APPWORK_HASH}\";/g" \
	-e "s/jdownloaderHash\s*=.*$/jdownloaderHash = \"${JDOWNLOADER_HASH}\";/g" \
	-e "s/jdbrowserHash\s*=.*$/jdbrowserHash = \"${JDBROWSER_HASH}\";/g" \
	-e "s/myJDownloaderHash\s*=.*$/myJDownloaderHash = \"${MYJDOWNLOADER_HASH}\";/g" \
    "$ROOT/default.nix"
