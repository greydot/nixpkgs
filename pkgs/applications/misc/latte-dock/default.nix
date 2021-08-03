{ mkDerivation, lib, cmake, xorg, plasma-framework, fetchurl, fetchFromGitHub
, extra-cmake-modules, karchive, kwindowsystem, qtx11extras, kcrash, knewstuff }:

mkDerivation rec {
  pname = "latte-dock";
  version = "0.10.0";

  src = fetchFromGitHub {
    repo = "latte-dock";
    owner = "KDE";
    rev = "2f6808b62608564692a15a28e65a42b8d38b06f3";
    sha256 = "127ry7236l8xjz20svbm5yryrvcs6j280g3jpqm70yhkpzkqarbv";
  };

  buildInputs = [ plasma-framework xorg.libpthreadstubs xorg.libXdmcp xorg.libSM ];

  nativeBuildInputs = [ extra-cmake-modules cmake karchive kwindowsystem
    qtx11extras kcrash knewstuff ];

  meta = with lib; {
    description = "Dock-style app launcher based on Plasma frameworks";
    homepage = "https://github.com/psifidotos/Latte-Dock";
    license = licenses.gpl2;
    platforms = platforms.unix;
    maintainers = [ maintainers.benley maintainers.ysndr ];
  };
}
