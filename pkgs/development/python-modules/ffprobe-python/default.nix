{ buildPythonPackage, fetchPypi, ffmpeg_5-full, lib, stdenv }:

buildPythonPackage rec {
  pname = "ffprobe-python";
  version = "1.0.3";

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-sdPmnmXggU4oV19jpHuDagt8yPH/7dYtJxUtnkSIIUo=";
  };

  doCheck = false;

  nativeBuildInputs = [ ffmpeg_5-full ];
}
