{ lib
, fetchPypi
, buildPythonPackage
, six
, flask
, pytest
}:

buildPythonPackage rec {
  pname = "pytest-pypi";
  version = "0.1.1";

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-TaLy6Id3tTsvPnr/ZgZYhvkOI7VfNFsVzPQEr7foiD4=";
  };

  propagatedBuildInputs = [ pytest ];

  buildInputs = [
    flask
    six
  ];

  # Doesn't include any tests
  doCheck = false;

  pythonImportsCheck = [ "pytest_pypi" ];

  meta = with lib; {
    description = "Easily test your HTTP library against a local copy of pypi";
    homepage = "https://github.com/kennethreitz/pytest-pypi";
    license = licenses.mit;
    maintainers = with maintainers; [ onny ];
  };
}
