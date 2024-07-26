{ lib, stdenv, fetchurl, dosfstools, libseccomp, makeWrapper, mtools, parted
, pkg-config, qemu_test, syslinux, util-linux }:

let
  version = "0.8.1";
  # list of all theoretically available targets
  targets = [
    "genode"
    "hvt"
    "muen"
    "spt"
    "virtio"
    "xen"
  ];
in stdenv.mkDerivation {
  pname = "solo5";
  inherit version;

  nativeBuildInputs = [ makeWrapper pkg-config ];
  buildInputs = lib.optional (stdenv.hostPlatform.isLinux) libseccomp;

  src = fetchurl {
    url = "https://github.com/Solo5/solo5/releases/download/v${version}/solo5-v${version}.tar.gz";
    sha256 = "sha256-J1xcL/AdcLQ7Ph3TFwEaS9l4cWjDQsTaXTdBDcT7p6E=";
  };

  patches = [
    (fetchurl {
      url = "https://github.com/wegank/solo5/commit/38bacb4155b54447dcbefff1fdc5260e5e6e31a7.patch";
      sha256 = "10dz4i1pvcdsv6pd9civipngfzs2k03wjaf65inh6jch1swm5r19";
    })
  ];

  hardeningEnable = [ "pie" ];

  configurePhase = ''
    runHook preConfigure
    sh configure.sh --prefix=/
    runHook postConfigure
  '';

  enableParallelBuilding = true;

  separateDebugInfo = true;
    # debugging requires information for both the unikernel and the tender

  installPhase = ''
    runHook preInstall
    export DESTDIR=$out
    export PREFIX=$out
    make install

    substituteInPlace $out/bin/solo5-virtio-mkimage \
      --replace "/usr/lib/syslinux" "${syslinux}/share/syslinux" \
      --replace "/usr/share/syslinux" "${syslinux}/share/syslinux" \
      --replace "cp " "cp --no-preserve=mode "

    wrapProgram $out/bin/solo5-virtio-mkimage \
      --prefix PATH : ${lib.makeBinPath [ dosfstools mtools parted syslinux ]}

    runHook postInstall
  '';

  doCheck = stdenv.hostPlatform.isLinux;
  nativeCheckInputs = [ util-linux qemu_test ];
  checkPhase = ''
    runHook preCheck
    patchShebangs tests
    ./tests/bats-core/bats ./tests/tests.bats
    runHook postCheck
  '';

  meta = with lib; {
    description = "Sandboxed execution environment";
    homepage = "https://github.com/solo5/solo5";
    license = licenses.isc;
    maintainers = [ maintainers.ehmry ];
    platforms = mapCartesianProduct ({ arch, os }: "${arch}-${os}") {
      arch = [ "aarch64" "x86_64" ];
      os = [ "freebsd" "genode" "linux" "openbsd" ];
    };
  };

}
