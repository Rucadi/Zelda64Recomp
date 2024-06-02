let
    pkgs = import <nixpkgs> {};
    mm = import ./nix/mm.nix {};
    N64Recomp = (builtins.getFlake "git+https://github.com/rucadi/N64Recomp?submodules=1").packages."${builtins.currentSystem}".N64Recomp;
in
pkgs.stdenv.mkDerivation {
  name = "majorasMask";
  src = ./.;
  nativeBuildInputs = [ N64Recomp pkgs.cmake pkgs.SDL2 pkgs.ninja pkgs.gtk3 pkgs.freetype];

  prePatch = ''
    cp ${mm}/* .
    N64Recomp us.rev1.toml
    RSPRecomp aspMain.us.rev1.toml
    RSPRecomp njpgdspMain.us.rev1.toml
  '';
}