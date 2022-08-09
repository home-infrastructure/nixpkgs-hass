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
# pydantic pinned to version 1.9.0 because of bug introduced in 1.9.1
# https://github.com/samuelcolvin/pydantic/issues/4092
, pydantic_190
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
  version = "4.0.12";
  format = "pyproject";

  disabled = pythonOlder "3.9";

  src = fetchFromGitHub {
    owner = "briis";
    repo = pname;
    rev = "refs/tags/v${version}";
    hash = "sha256-xbODjgJHd1e3NdnoB/srlOdeuhOj2JeN8b8MQh3D4+A=";
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
    pydantic_190
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
