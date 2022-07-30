{ lib
, aiofiles
, aiohttp
, aioshutil
, buildPythonPackage
, fetchFromGitHub
, ipython
, orjson
, packaging
, pillow
, poetry-core
, pydantic
, pyjwt
, pytest-aiohttp
, pytest-asyncio
, pytest-benchmark
, pytest-timeout
, pytest-xdist
, pytestCheckHook
, python-dotenv
, pythonOlder
, pytz
, termcolor
, typer
, ffprobe-python
}:

buildPythonPackage rec {
  pname = "pyunifiprotect";
  version = "4.0.11";
  format = "pyproject";

  disabled = pythonOlder "3.9";

  src = fetchFromGitHub {
    owner = "briis";
    repo = pname;
    rev = "refs/tags/v${version}";
    hash = "sha256-81nottXXenkIPiDnR8O44ELStoh8i2yROYCPvBLiWSU=";
  };

  postPatch = ''
    substituteInPlace pyproject.toml \
      --replace "--cov=pyunifiprotect --cov-append" ""
  '';

  propagatedBuildInputs = [
    aiofiles
    aiohttp
    aioshutil
    orjson
    packaging
    pillow
    pydantic
    pyjwt
    pytz
    typer
  ];

  passthru.optional-dependencies = {
    shell = [
      ipython
      python-dotenv
      termcolor
    ];
  };

  checkInputs = [
    ffprobe-python
    pytest-aiohttp
    pytest-asyncio
    pytest-benchmark
    pytest-timeout
    pytest-xdist
    pytestCheckHook
  ];

  pythonImportsCheck = [
    "pyunifiprotect"
  ];

  pytestFlagsArray = [
    "--benchmark-disable"
  ];

  meta = with lib; {
    description = "Library for interacting with the Unifi Protect API";
    homepage = "https://github.com/briis/pyunifiprotect";
    license = with licenses; [ mit ];
    maintainers = with maintainers; [ fab ];
  };
}
