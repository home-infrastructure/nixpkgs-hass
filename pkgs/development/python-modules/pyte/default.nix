{ lib
, buildPythonPackage
, fetchFromGitHub
, pytestCheckHook
, pytest-runner
, wcwidth }:

buildPythonPackage rec {
  pname = "pyte";
  version = "0.8.1";

  src = fetchFromGitHub {
    owner = "selectel";
    repo = pname;
    rev = version;
    sha256 = "sha256-gLvsW4ou6bGq9CxT6XdX+r2ViMk7z+aejemrdLwJb3M=";
  };

  nativeBuildInputs = [ pytest-runner ];

  propagatedBuildInputs = [ wcwidth ];

  checkInputs = [ pytestCheckHook ];

  meta = with lib; {
    description = "Simple VTXXX-compatible linux terminal emulator";
    homepage = "https://github.com/selectel/pyte";
    license = licenses.lgpl3;
    maintainers = with maintainers; [ flokli ];
  };
}
