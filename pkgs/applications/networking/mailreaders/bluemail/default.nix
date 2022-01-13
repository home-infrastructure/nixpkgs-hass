{ stdenv
, lib
, fetchurl
, dpkg
, autoPatchelfHook
, pango
, gtk3
, alsa-lib
, nss
, libXdamage
, libdrm
, mesa
, libxshmfence }:

stdenv.mkDerivation rec {
  pname = "bluemail";
  version = "1.1.119";

  src = fetchurl {
    url = "https://download.bluemail.me/BlueMail/deb/BlueMail.deb";
    sha256 = "sha256-f8DWyO3vfjJsk+lt5Ihlsdh+0m1whGSLYwdBO9BWPFQ=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    dpkg
  ];

  buildInputs = [
    pango
    gtk3
    alsa-lib
    nss
    libXdamage
    libdrm
    mesa
    libxshmfence
  ];

  unpackCmd = "${dpkg}/bin/dpkg-deb -x $src debcontents";

  dontBuild = true;
  dontStrip = true;

  installPhase = ''
    mkdir -p $out/bin
    mv opt/BlueMail/* $out
    ln -s $out/bluemail $out/bin/bluemail
  '';

  meta = with lib; {
    description = "Free, secure, universal email app, capable of managing an unlimited number of mail accounts";
    homepage = "https://bluemail.me";
    license = licenses.unfree;
    platforms = platforms.linux;
    maintainers = with maintainers; [ onny ];
  };
}
