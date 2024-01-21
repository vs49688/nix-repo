{ writeShellApplication, lib, bento4, xxd }:
(writeShellApplication {
  name = "aaxm4bfix";

  runtimeInputs = [ bento4 xxd ];

  text = ''
    [[ $# -ne 1 ]] && (echo "Usage: $0 <file.m4b>" && exit 2)

    f="$1"
    t=$(mktemp)
    mp4extract moov/trak/mdia/minf/stbl/stsd/mp4a/esds        "$f" /dev/stdout | xxd -p | tr -d '\n' >"$t"
    magic=$(sed -re 's/^.*0580808002(....).*$/\1/' "$t")
    if [ "$magic" != "1212" ]; then
        echo "no need to fix"
        rm "$t"
        exit 0
    fi
    t2=$(mktemp)
    sed -re 's/05808080021212/05808080021210/' "$t" | xxd -r -p >"$t2"
    rm "$t"
    old="''${f}.pre-fix"
    mv -v "$f" "$old"
    mp4edit --replace        moov/trak/mdia/minf/stbl/stsd/mp4a/esds:"$t2"        "$old"        "$f"
  '';
}).overrideAttrs(old: {
  meta = with lib; {
    homepage    = "https://rentry.co/n4ost";
    platforms   = platforms.linux;
    license     = licenses.free;
    maintainers = with maintainers; [ zane ];
  };
})
