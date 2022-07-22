{ stdenv
, lib
, fetchFromGitHub
, cmake
, clang
, libclang
, zlib
, openexr
, openimageio2
, llvm
, boost165
, flex
, bison
, partio
, pugixml
, util-linux
, python3 }:

let

  boost_static = boost165.override { enableStatic = true; };

in stdenv.mkDerivation rec {
  pname = "openshadinglanguage";
  version = "1.11.17.0";

  src = fetchFromGitHub {
    owner = "AcademySoftwareFoundation";
    repo = "OpenShadingLanguage";
    rev = "v${version}";
    sha256 = "sha256-2OOkLnHLz+vmSeEDQl12SrJBTuWwbnvoTatnvm8lpbA=";
  };

  cmakeFlags = [
    "-DUSE_BOOST_WAVE=ON"
    "-DENABLE_RTTI=ON"

    # Build system implies llvm-config and llvm-as are in the same directory.
    # Override defaults.
    "-DLLVM_DIRECTORY=${llvm}"
    "-DLLVM_CONFIG=${llvm.dev}/bin/llvm-config"

    # Set C++11 to C++14 required for LLVM10+
    "-DCMAKE_CXX_STANDARD=14"
  ];

  preConfigure = "patchShebangs src/liboslexec/serialize-bc.bash ";

  nativeBuildInputs = [
    clang
    cmake
    boost_static
    flex
    bison
  ];

  buildInputs = [
    libclang
    zlib
    openexr
    openimageio2
    llvm
    partio
    pugixml
    util-linux # needed just for hexdump
    python3
    python3.pkgs.pybind11
  ];

  meta = with lib; {
    broken = (stdenv.isLinux && stdenv.isAarch64);
    description = "Advanced shading language for production GI renderers";
    homepage = "https://opensource.imageworks.com/osl.html";
    maintainers = with maintainers; [ hodapp ];
    license = licenses.bsd3;
    platforms = platforms.linux;
  };
}
