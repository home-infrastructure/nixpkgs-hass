{ lib, fetchPypi, buildPythonPackage }:

buildPythonPackage rec {
  pname = "js2py";
  version = "0.71";

  src = fetchPypi {
    inherit version;
    pname = "Js2Py";
    sha256 = "0n1k83ww0pr4q6z0h7p8hvy21hcgb96jvgllfbwhvvyf37h3w182";
  };

  meta = with lib; {
    description = "JavaScript to Python Translator & JavaScript interpreter written in 100% pure Python";
    homepage = "https://github.com/PiotrDabkowski/Js2Py";
    license = licenses.mit;
    maintainers = with maintainers; [ onny ];
  };
}
