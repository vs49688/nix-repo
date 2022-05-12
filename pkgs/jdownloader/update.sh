#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl subversion gnugrep nix-prefetch-svn jq

set -euo pipefail

prefetch() {
	nix-prefetch-svn "$1" "$2" | grep -E '^[a-z0-9]{52}$' | head -1
}

ROOT="$(dirname "$(readlink -f "$0")")"
if [[ ! "$(basename $ROOT)" == "jdownloader" || ! -f "$ROOT/default.nix" ]]; then
    echo "ERROR: Not in the jdownloader folder"
    exit 1
fi

# TODO: fetch build.json when they provide it
# curl -o build.json https://jdownloader.org/path/to/build.json

AWU_REV=$(jq .AppWorkUtilsRevision build.json)
[[ $AWU_REV != "null" ]] || (echo "build.json missing 'AppWorkUtilsRevision' key." && exit 1)

JD2_REV=$(jq .JDownloaderRevision build.json)
[[ $JD2_REV != "null" ]] || (echo "build.json missing 'JDownloaderRevision' key." && exit 1)

JDBROWSER_REV=$(jq .JDBrowserRevision build.json)
[[ $JDBROWSER_REV != "null" ]] || (echo "build.json missing 'JDBrowserRevision' key." && exit 1)

MYJDOWNLOADER_REV=$(jq .MyJDownloaderClientRevision build.json)
[[ $MYJDOWNLOADER_REV != "null" ]] || (echo "build.json missing 'MyJDownloaderClientRevision' key." && exit 1)

echo "INFO: AppWorkUtils        revision is $AWU_REV"
echo "INFO: JDownloader2        revision is $JD2_REV"
echo "INFO: JDBrowser           revision is $JDBROWSER_REV"
echo "INFO: MyJDownloaderClient revision is $MYJDOWNLOADER_REV"

APPWORK_HASH=$(prefetch svn://svn.appwork.org/utils "$AWU_REV")
echo "INFO: AppWorkUtils SHA256 is $APPWORK_HASH"

JDOWNLOADER_HASH=$(prefetch svn://svn.jdownloader.org/jdownloader/trunk "$JD2_REV")
echo "INFO: JDownloader2 SHA256 is $JDOWNLOADER_HASH"

JDBROWSER_HASH=$(prefetch svn://svn.jdownloader.org/jdownloader/browser "$JDBROWSER_REV")
echo "INFO: JDBrowser SHA256 is $JDBROWSER_HASH"

MYJDOWNLOADER_HASH=$(prefetch svn://svn.jdownloader.org/jdownloader/MyJDownloaderClient "$MYJDOWNLOADER_REV")
echo "INFO: MyJDownloader SHA256 is $MYJDOWNLOADER_HASH"

sed -i -E \
	-e "s/appWorkHash\s*=.*$/appWorkHash = \"${APPWORK_HASH}\";/g" \
	-e "s/jdownloaderHash\s*=.*$/jdownloaderHash = \"${JDOWNLOADER_HASH}\";/g" \
	-e "s/jdbrowserHash\s*=.*$/jdbrowserHash = \"${JDBROWSER_HASH}\";/g" \
	-e "s/myJDownloaderHash\s*=.*$/myJDownloaderHash = \"${MYJDOWNLOADER_HASH}\";/g" \
    "$ROOT/default.nix"
