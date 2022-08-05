{ buildPythonPackage, fetchPypi, lib, stdenv }:

buildPythonPackage rec {
  pname = "ffprobe-python";
  version = "1.0.3";

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-UaqAMJHJjTZYhKDixX1CAvvzu3UkMGcLNawCTB2DXZx=";
  };

  doCheck = false;

  propagatedBuildInputs = [ ];
}
