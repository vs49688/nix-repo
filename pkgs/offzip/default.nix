{ stdenv, lib, fetchzip, zlib }:
stdenv.mkDerivation {
  pname   = "offzip";
  version = "0.4.1";

  src = fetchzip {
    url       = "https://aluigi.altervista.org/mytoolz/offzip.zip";
    sha256    = "19lcddhjccnay77g1w8dz08k2ldbpqmpd0pc0s2ixgsdvd4iwrkn";
    stripRoot = false;
  };

  buildInputs = [ zlib ];

  makeFlags = [ "PREFIX=$(out)" ];

  meta = with lib; {
    homepage    = "https://aluigi.altervista.org/mytoolz.htm";
    platforms   = platforms.all;
    license     = licenses.gpl2Plus;
    maintainers = with maintainers; [ zane ];
  };
}
