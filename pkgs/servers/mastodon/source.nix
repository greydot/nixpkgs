# This file was generated by pkgs.mastodon.updateScript.
{ fetchFromGitHub, applyPatches }: let
  src = fetchFromGitHub {
    owner = "mastodon";
    repo = "mastodon";
    rev = "v4.1.3";
    sha256 = "F+cpL+ZFfe52f82qtJxuxRCILW3zr6K5OMrvaOgWe58=";
  };
in applyPatches {
  inherit src;
  patches = [];
}
