{ lib
, pkgs
, stdenv

  # Build-time dependencies:
, addOpenGLRunpath
, bazel_5
, binutils
, buildBazelPackage
, buildPythonPackage
, curl
, cython
, fetchFromGitHub
, git
, jsoncpp
, libcxx
, nsync
, openssl
, pybind11
, setuptools
, symlinkJoin
, wheel
, which

  # Python dependencies:
, absl-py
, flatbuffers
, numpy
, scipy
, six

  # Runtime dependencies:
, double-conversion
, giflib
, grpc
, libjpeg_turbo
, python
, snappy
, zlib

  # CUDA flags:
, cudaCapabilities ? [ "sm_35" "sm_50" "sm_60" "sm_70" "sm_75" "compute_80" ]
, cudaSupport ? false
, cudaPackages ? { }

  # MKL:
, mklSupport ? true
}:

let

  inherit (cudaPackages) cudatoolkit cudnn nccl;

  pname = "jaxlib";
  version = "0.3.15";

  meta = with lib; {
    description = "JAX is Autograd and XLA, brought together for high-performance machine learning research.";
    homepage = "https://github.com/google/jax";
    license = licenses.asl20;
    maintainers = with maintainers; [ ndl ];
    platforms = [ "x86_64-linux" "aarch64-darwin" "x86_64-darwin" ];
    hydraPlatforms = [ "x86_64-linux" ]; # Don't think anybody is checking the darwin builds
  };

  cudatoolkit_joined = symlinkJoin {
    name = "${cudatoolkit.name}-merged";
    paths = [
      cudatoolkit.lib
      cudatoolkit.out
    ] ++ lib.optionals (lib.versionOlder cudatoolkit.version "11") [
      # for some reason some of the required libs are in the targets/x86_64-linux
      # directory; not sure why but this works around it
      "${cudatoolkit}/targets/${stdenv.system}"
    ];
  };

  cudatoolkit_cc_joined = symlinkJoin {
    name = "${cudatoolkit.cc.name}-merged";
    paths = [
      cudatoolkit.cc
      binutils.bintools # for ar, dwp, nm, objcopy, objdump, strip
    ];
  };

  llvm-raw_darwin_patched = stdenv.mkDerivation {
    name = "llvm-raw-${pname}-${version}";

    src = _bazel-build.deps;

    prePatch = "pushd llvm-raw";
    patches = [
      # Fix a vendored config.h that requires the 10.13 SDK
      ./llvm_bazel_fix_macos_10_12_sdk.patch
    ];
    postPatch = ''
      touch {BUILD,WORKSPACE}
      popd
    '';

    dontConfigure = true;
    dontBuild = true;

    installPhase = ''
      runHook preInstall

      mv llvm-raw/ "$out"

      runHook postInstall
    '';
  };
  bazel-build = if stdenv.isDarwin then _bazel-build.overrideAttrs (prev: {
    bazelBuildFlags = prev.bazelBuildFlags ++ [
      # "--override_repository=rules_cc=${rules_cc_darwin_patched}"

      # Fixes error: no member named 'futimens' in the global namespace
      "--override_repository=llvm-raw=${llvm-raw_darwin_patched}"
    ];
    # preBuild = ''
    #   export AR="${cctools}/bin/libtool"
    # '';
  }) else _bazel-build;

  _bazel-build = (buildBazelPackage.override (lib.optionalAttrs stdenv.isDarwin {
    # clang 7 fails to emit a symbol for
    # __ZN4llvm11SmallPtrSetIPKNS_10AllocaInstELj8EED1Ev in any of the
    # translation units, so the build fails at link time
    # stdenv = llvmPackages_11.stdenv;
  })) {
    name = "bazel-build-${pname}-${version}";

    bazel = bazel_5;

    src = fetchFromGitHub {
      owner = "google";
      repo = "jax";
      rev = "${pname}-v${version}";
      sha256 = "sha256-pIl7zzl82w5HHnJadH2vtCT4mYFd5YmM9iHC2GoJD6s=";
    };

    nativeBuildInputs = [
      cython
      pkgs.flatbuffers
      git
      setuptools
      wheel
      which
    ];

    buildInputs = [
      curl
      double-conversion
      giflib
      grpc
      jsoncpp
      libjpeg_turbo
      numpy
      openssl
      pkgs.flatbuffers
      pkgs.protobuf
      pybind11
      scipy
      six
      snappy
      zlib
    ] ++ lib.optionals cudaSupport [
      cudatoolkit
      cudnn
    ] ++ lib.optionals (!stdenv.isDarwin) [
      nsync
    ];

    postPatch = ''
      rm -f .bazelversion
    '';

    bazelTarget = "//build:build_wheel";

    removeRulesCC = false;

    GCC_HOST_COMPILER_PREFIX = lib.optionalString cudaSupport "${cudatoolkit_cc_joined}/bin";
    GCC_HOST_COMPILER_PATH = lib.optionalString cudaSupport "${cudatoolkit_cc_joined}/bin/gcc";
    NIX_CFLAGS_COMPILE = lib.optionalString stdenv.isDarwin "-I${lib.getDev libcxx}/include/c++/v1";

    preConfigure = ''
      # dummy ldconfig
      mkdir dummy-ldconfig
      echo "#!${stdenv.shell}" > dummy-ldconfig/ldconfig
      chmod +x dummy-ldconfig/ldconfig
      export PATH="$PWD/dummy-ldconfig:$PATH"
      cat <<CFG > ./.jax_configure.bazelrc
      build --strategy=Genrule=standalone
      build --repo_env PYTHON_BIN_PATH="${python}/bin/python"
      build --action_env=PYENV_ROOT
      build --python_path="${python}/bin/python"
      build --distinct_host_configuration=false
    '' + lib.optionalString cudaSupport ''
      build --action_env CUDA_TOOLKIT_PATH="${cudatoolkit_joined}"
      build --action_env CUDNN_INSTALL_PATH="${cudnn}"
      build --action_env TF_CUDA_PATHS="${cudatoolkit_joined},${cudnn},${nccl}"
      build --action_env TF_CUDA_VERSION="${lib.versions.majorMinor cudatoolkit.version}"
      build --action_env TF_CUDNN_VERSION="${lib.versions.major cudnn.version}"
      build:cuda --action_env TF_CUDA_COMPUTE_CAPABILITIES="${lib.concatStringsSep "," cudaCapabilities}"
    '' + ''
      CFG
    '';

    # Copy-paste from TF derivation.
    # Most of these are not really used in jaxlib compilation but it's simpler to keep it
    # 'as is' so that it's more compatible with TF derivation.
    TF_SYSTEM_LIBS = lib.concatStringsSep "," ([
      "absl_py"
      "astor_archive"
      "astunparse_archive"
      "boringssl"
      # Not packaged in nixpkgs
      # "com_github_googleapis_googleapis"
      # "com_github_googlecloudplatform_google_cloud_cpp"
      "com_github_grpc_grpc"
      # Fails with the error: /build/output/external/com_google_protobuf/BUILD.bazel:50:8: in cmd attribute of genrule rule @com_google_protobuf//:link_proto_files: $(PROTOBUF_INCLUDE_PATH) not defined
      # "com_google_protobuf"
      # Fails with the error: external/org_tensorflow/tensorflow/core/profiler/utils/tf_op_utils.cc:46:49: error: no matching function for call to 're2::RE2::FullMatch(absl::lts_2020_02_25::string_view&, re2::RE2&)'
      # "com_googlesource_code_re2"
      "curl"
      "cython"
      "dill_archive"
      "double_conversion"
      "flatbuffers"
      "functools32_archive"
      "gast_archive"
      "gif"
      "hwloc"
      "icu"
      "jsoncpp_git"
      "libjpeg_turbo"
      "lmdb"
      "nasm"
      "opt_einsum_archive"
      "org_sqlite"
      "pasta"
      "png"
      "pybind11"
      "six_archive"
      "snappy"
      "tblib_archive"
      "termcolor_archive"
      "typing_extensions_archive"
      "wrapt"
      "zlib"
    ] ++ lib.optionals (!stdenv.isDarwin) [
      "nsync" # fails to build on darwin
    ]);

    # Make sure Bazel knows about our configuration flags during fetching so that the
    # relevant dependencies can be downloaded.
    bazelFetchFlags = _bazel-build.bazelBuildFlags;

    bazelBuildFlags = [
      "-c opt"
    ] ++ lib.optional (stdenv.targetPlatform.isx86_64 && stdenv.targetPlatform.isUnix) [
      "--config=avx_posix"
    ] ++ lib.optional cudaSupport [
      "--config=cuda"
    ] ++ lib.optional mklSupport [
      "--config=mkl_open_source_only"
    ] ++ lib.optionals stdenv.cc.isClang [
      # workaround for https://github.com/bazelbuild/bazel/issues/15359
      "--spawn_strategy=sandboxed"
    ];

    fetchAttrs = {
      sha256 =
        if cudaSupport then
          "sha256-FOQT6w7wmS/4lIs1EZIAyycF0HRdbcg/w/34esxUKyw="
        else
          if stdenv.isDarwin then
            "sha256-GKhsnIMX5pUwDb2cFue0GMGHh0HLcfDk6Iy9DOTfEnY="
          else
            "sha256-MSQ4rwGVuekvH3ZjWlkLW041UkfTKtoXtQnSyXlWCes=";
    };

    buildAttrs = {
      outputs = [ "out" ];

      # Note: we cannot do most of this patching at `patch` phase as the deps are not available yet.
      # 1) Fix pybind11 include paths.
      # 2) Force static protobuf linkage to prevent crashes on loading multiple extensions
      #    in the same python program due to duplicate protobuf DBs.
      # 3) Patch python path in the compiler driver.
      preBuild = ''
        for src in ./jaxlib/*.{cc,h} ./jaxlib/cuda/*.{cc,h}; do
          sed -i 's@include/pybind11@pybind11@g' $src
        done
        sed -i 's@-lprotobuf@-l:libprotobuf.a@' ../output/external/org_tensorflow/third_party/systemlibs/protobuf.BUILD
        sed -i 's@-lprotoc@-l:libprotoc.a@' ../output/external/org_tensorflow/third_party/systemlibs/protobuf.BUILD
      '' + lib.optionalString cudaSupport ''
        patchShebangs ../output/external/org_tensorflow/third_party/gpus/crosstool/clang/bin/crosstool_wrapper_driver_is_not_gcc.tpl
      '';

      installPhase = ''
        ./bazel-bin/build/build_wheel --output_path=$out --cpu=${stdenv.targetPlatform.linuxArch}
      '';
    };

    inherit meta;
  };

in
buildPythonPackage {
  inherit meta pname version;
  format = "wheel";

  src = "${bazel-build}/jaxlib-${version}-cp${builtins.replaceStrings ["."] [""] python.pythonVersion}-none-manylinux2014_${stdenv.targetPlatform.linuxArch}.whl";

  # Note that cudatoolkit is necessary since jaxlib looks for "ptxas" in $PATH.
  # See https://github.com/NixOS/nixpkgs/pull/164176#discussion_r828801621 for
  # more info.
  postInstall = lib.optionalString cudaSupport ''
    mkdir -p $out/bin
    ln -s ${cudatoolkit}/bin/ptxas $out/bin/ptxas

    find $out -type f \( -name '*.so' -or -name '*.so.*' \) | while read lib; do
      addOpenGLRunpath "$lib"
      patchelf --set-rpath "${cudatoolkit}/lib:${cudatoolkit.lib}/lib:${cudnn}/lib:${nccl}/lib:$(patchelf --print-rpath "$lib")" "$lib"
    done
  '';

  nativeBuildInputs = lib.optional cudaSupport addOpenGLRunpath;

  propagatedBuildInputs = [
    absl-py
    curl
    double-conversion
    flatbuffers
    giflib
    grpc
    jsoncpp
    libjpeg_turbo
    numpy
    scipy
    six
    snappy
  ];

  pythonImportsCheck = [ "jaxlib" ];

  # Without it there are complaints about libcudart.so.11.0 not being found
  # because RPATH path entries added above are stripped.
  dontPatchELF = cudaSupport;
}
