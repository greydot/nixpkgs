{
  lib,
  stdenv,
  fetchFromGitHub,
  replaceVars,

  qt6,

  shadps4,
  symlinkJoin,
}:

let
  shadps4Wrapped = symlinkJoin {
    name = "shadps4-wrapped";
    paths = [ shadps4 ];

    postBuild = ''
      substitute ${./versions.json} $out/share/versions.json \
        --replace-fail @shadps4@ $out/bin/shadps4

      substitute ${./qt_ui.ini} $out/share/qt_ui.ini \
        --replace-fail @shadps4@ $out/bin/shadps4
    '';
  };

in
stdenv.mkDerivation (finalAttrs: {
  pname = "shadps4-qt";
  version = "224";

  inherit (shadps4)
    postPatch
    cmakeBuildType
    dontStrip
    runtimeDependencies
    ;

  src = fetchFromGitHub {
    owner = "shadps4-emu";
    repo = "shadps4-qtlauncher";
    tag = "v${finalAttrs.version}";
    hash = "sha256-slYlh7uUM1W1rakfGl2GEcq/MsgxRVuyAVZJJk1YpmQ=";
    fetchSubmodules = true;

    leaveDotGit = true;
    postCheckout = ''
      cd "$out"
      git rev-parse --short=8 HEAD > $out/COMMIT
      date -u -d "@$(git log -1 --pretty=%ct)" "+%Y-%m-%dT%H:%M:%SZ" > $out/SOURCE_DATE_EPOCH
      find "$out" -name .git -print0 | xargs -0 rm -rf
    '';
  };

  strictDeps = true;
  __structuredAttrs = true;

  patches = [
    (replaceVars ./qt-paths.patch {
      shadps4 = shadps4Wrapped;
    })
  ];

  nativeBuildInputs = (shadps4.nativeBuildInputs or [ ]) ++ [
    qt6.wrapQtAppsHook
  ];

  buildInputs = (shadps4.buildInputs or [ ]) ++ [
    qt6.qtbase
    qt6.qttools
    qt6.qtmultimedia
  ];

  cmakeFlags = [
    (lib.cmakeBool "ENABLE_UPDATER" false)
    (lib.cmakeBool "HIDE_VERSION_MANAGER" true)
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    ln -s ${shadps4Wrapped}/bin/shadps4 $out/bin

    install -Dm644 $src/.github/shadps4.png $out/share/icons/hicolor/512x512/apps/net.shadps4.shadPS4.png
    install -Dm644 -t $out/share/applications $src/dist/net.shadps4.shadps4-qtlauncher.desktop
    install -Dm644 -t $out/share/metainfo $src/dist/net.shadps4.shadps4-qtlauncher.metainfo.xml

    install -Dm755 shadPS4QtLauncher $out/bin/shadps4-qt

    runHook postInstall
  '';

  fixupPhase = ''
    runHook preFixup

    substituteInPlace $out/share/applications/net.shadps4.shadps4-qtlauncher.desktop \
      --replace-fail 'Exec=shadPS4QtLauncher' 'Exec=shadps4-qt'

    runHook postFixup
  '';

  meta = {
    inherit (shadps4.meta)
      platforms
      license
      maintainers
      ;

    description = shadps4.meta.description + " (Qt UI)";
    homepage = "https://github.com/shadps4-emu/shadps4-qtlauncher";
    mainProgram = "shadps4-qt";
  };
})
