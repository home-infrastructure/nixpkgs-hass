{ lib, stdenv, fetchFromGitHub, lazarus, fpc, pango, cairo, glib
, atk, gtk2, libX11, gdk-pixbuf, busybox, python3, makeWrapper }:

with stdenv;

let
  bgrabitmap = fetchFromGitHub {
    owner = "bgrabitmap";
    repo = "bgrabitmap";
    rev = "v11.5";
    sha256 = "sha256-Pevh+yhtN3oSSvbQfnO7SM6UHBVe0sSpbK8ss98XqcU=";
  };
  bgracontrols = fetchFromGitHub {
    owner = "bgrabitmap";
    repo = "bgracontrols";
    rev = "v7.5";
    sha256 = "sha256-iGrj5aiviwr/FK85H8yYyZUrSVMeXkh+U2AgyNndLFw=";
  };
in stdenv.mkDerivation rec {
  pname = "lazpaint";
  version = "7.1.6";

  src = fetchFromGitHub {
    owner = "bgrabitmap";
    repo = "lazpaint";
    rev = "v${version}";
    sha256 = "sha256-DrRcrBm1nmOeACN5zo7KS0cv6+6mYTGUkhEXRKdpZao=";
  };

  nativeBuildInputs = [ lazarus fpc makeWrapper ];

  buildInputs = [ pango cairo glib atk gtk2 libX11 gdk-pixbuf ];

  NIX_LDFLAGS = "--as-needed -rpath ${lib.makeLibraryPath buildInputs}";

  buildPhase = ''
    cp -r --no-preserve=mode ${bgrabitmap} bgrabitmap
    cp -r --no-preserve=mode ${bgracontrols} bgracontrols

    lazbuild --lazarusdir=${lazarus}/share/lazarus \
      --build-mode=Release \
      bgrabitmap/bgrabitmap/bgrabitmappack.lpk \
      bgracontrols/bgracontrols.lpk \
      lazpaintcontrols/lazpaintcontrols.lpk \
      lazpaint/lazpaint.lpi
  '';

  installPhase = ''
    # Reuse existing install script
    cd lazpaint/release/debian
    substituteInPlace makedeb.sh --replace "rm -rf" "ls"
    patchShebangs ./makedeb.sh
    PATH=$PATH:${busybox}/bin ./makedeb.sh
    cp -r staging/usr $out

    # Python is needed for scripts
    makeWrapper $out/share/lazpaint/lazpaint $out/bin/lazpaint \
      --prefix PATH : ${lib.makeBinPath [ python3 ]}
  '';

  meta = with lib; {
    # Currently broken with latest stable lazarus version
    # Should work when lazarus >= 2.3 gets released
    # https://github.com/bgrabitmap/lazpaint/issues/512
    broken = true;
    description = "Image editor like PaintBrush or Paint.Net";
    homepage = "https://lazpaint.github.io";
    license = licenses.gpl3;
    platforms = platforms.linux;
    maintainers = with maintainers; [ onny ];
  };
}
