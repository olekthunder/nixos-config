{ stdenv, lib, fetchurl }:

stdenv.mkDerivation rec {
  name = "lets-${version}";

  version = "0.0.33";

  src = fetchurl {
      url = "https://github.com/lets-cli/lets/releases/download/v${version}/lets_Linux_x86_64.tar.gz";
      sha256 = "19694f806e33676f0d8f1c252147fcfd1aa1c70bc71e1ad1f8e74672be5a5511";
  };

  # Work around the "unpacker appears to have produced no directories"
  # case that happens when the archive doesn't have a subdirectory.
  setSourceRoot = "sourceRoot=`pwd`";

  installPhase = ''
    tar xzvf $src
    install -m755 -D lets $out/bin/lets
  '';

  meta = with lib; {
    homepage = "https://lets-cli.org/";
    description = "CLI task runner for productive developers";
    platforms = platforms.linux;
  };
}