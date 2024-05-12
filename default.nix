{majorasMaskN64? ./zeldamm.n64 ,majorasMaskElf ? ./mm-n64-us.elf}:
let
 pkgs = import <nixpkgs> {};

 _mipsBinutils = {stdenv, fetchurl, patchelf, glibc} : stdenv.mkDerivation {
    name = "mipsBinutils";
    src =  fetchurl {
    url ="https://github.com/decompals/mips-binutils-egcs-2.9.5/releases/latest/download/mips-binutils-egcs-2.9.5-linux.tar.gz";
    sha256 = "04pdjk5n7xw7y4xamc4nisq0vdipsxgpq3jmd7j48gfn0hx9kz21";
  };
   postInstall = ''
    mkdir -p $out/bin
    cp * $out/bin
    for f in $(find $out/bin -type f); do
        ${patchelf}/bin/patchelf --set-interpreter "${glibc}/lib/ld-linux-x86-64.so.2" $f || true
        cp $f $out/bin/mips-linux-gnu-$(basename $f)
        rm $f
    done
   '';
   sourceRoot = ".";
 };

 mipsBinutils = pkgs.callPackage _mipsBinutils {};

 _allMipsTools = {stdenv, fetchurl, patchelf, glibc} : let 
        gcc-papermario = builtins.fetchurl {
            url =
            "https://github.com/pmret/gcc-papermario/releases/download/master/linux.tar.gz";
            sha256 = "1156cf0d6a88a64c20e2a10fc9445d99cb9a38518f432b1669528dfa82ebb45f";
        };

        binutils-papermario = builtins.fetchurl {
            url =
            "https://github.com/pmret/binutils-papermario/releases/download/master/linux.tar.gz";
            sha256 = "c3cd88db47ac41f78b557042c7e7ad47ac9c04cee6f0d1069a489c1c9e8c103c";
        };

        mips-gcc-272 = builtins.fetchurl {
            url =
            "https://github.com/decompals/mips-gcc-2.7.2/releases/download/main/gcc-2.7.2-linux.tar.gz";
            sha256 = "ff3e299c1d952c0a5cb39f7790a208d0c547cf93986eb5607f820c935cedc288";
        };

        mips-binutils-26 = builtins.fetchurl {
            url =
            "https://github.com/decompals/mips-binutils-2.6/releases/download/main/binutils-2.6-linux.tar.gz";
            sha256 = "405a7ddb29a0b2eb472b167e8f15472223df1eff3093a5ff31d6e545d3a6c670";
        };

        egcs-binutils = builtins.fetchurl {
            url =
            "https://github.com/decompals/mips-binutils-egcs-2.9.5/releases/latest/download/mips-binutils-egcs-2.9.5-linux.tar.gz";
            sha256 = "04pdjk5n7xw7y4xamc4nisq0vdipsxgpq3jmd7j48gfn0hx9kz21";
        };

        egcs-gcc = builtins.fetchurl {
            url =
            "https://github.com/decompals/mips-gcc-egcs-2.91.66/releases/latest/download/mips-gcc-egcs-2.91.66-linux.tar.gz";
            sha256 = "03v1ci7j0hi53z639rwj60xwz0zzi82a9azi0yiw818r754faql0";
        };
    in stdenv.mkDerivation {
        name = "miptools";
    src = ./.;

    postInstall = ''
        mkdir -p $out/bin
        tar zx -C $out/bin -f ${gcc-papermario}
        tar zx -C $out/bin -f ${binutils-papermario}
        tar zx -C $out/bin -f ${mips-gcc-272}
        tar zx -C $out/bin -f ${mips-binutils-26}
        tar zx -C $out/bin -f ${egcs-binutils}
        tar zx -C $out/bin -f ${egcs-gcc}

        for f in $(find $out/bin -type f); do
            ${patchelf}/bin/patchelf --set-interpreter "${glibc}/lib/ld-linux-x86-64.so.2" $f || true
            cp $f $out/bin/mips-linux-gnu-$(basename $f)
            rm $f
        done
   '';
 };

allMipsTools = pkgs.callPackage _allMipsTools {};

mm = pkgs.callPackage _mm {};

 _n64ToElf = {stdenv, toybox}: ROM64: 
 stdenv.mkDerivation
 {
    name = "rom2elf";
    src = ROM64;
    dontUnpack = true;

    nativeBuildInputs = [toybox];
    postInstall = ''
        # Get entry point from N64 ROM
        dd if=$src bs=1 skip=8 count=4 of=entrypoint >& /dev/null
        # Construct an ELF
        ${mipsBinutils}/bin/objcopy -I binary $src -O elf32-bigmips  --adjust-section-vma .data+0x80000000 foo.elf
        # Patch to MIPS III
        printf '\x20\x00\x00\x00' | dd bs=1 seek=36 count=4 conv=notrunc of=foo.elf >& /dev/null
        # Set entrypoint
        dd if=entrypoint bs=1 seek=24 count=4 conv=notrunc of=foo.elf >& /dev/null
        cp foo.elf $out
    '';
 };
 n64ToElf = pkgs.callPackage _n64ToElf {};

 _n64Recomp = {stdenv, fetchFromGitHub, cmake} : stdenv.mkDerivation 
 {
        pname = "N64Recomp";
        version = "1.0.0";
        src = fetchFromGitHub {
              owner = "Mr-Wiseguy";
              repo = "N64Recomp";
              rev = "dbf0e623c8a1cbb3e73237803a8bcc29f32816d6";
              deepClone = true;
              fetchSubmodules = true;
              hash = "sha256-RUcBd9vB1oFgveHPBjShSlAv+J26/fGCN0/P6atuyo4=";
            };
        nativeBuildInputs = [cmake];

        installPhase = ''
                mkdir -p $out/bin
                cp N64Recomp $out/bin
                cp RSPRecomp $out/bin
            '';
 };

 N64Recomp = pkgs.callPackage _n64Recomp {};

 _zelda64 = {stdenv, fetchFromGitHub, cmake, pkg-config, SDL2, freetype, shaderc, xrandr,  gtk3} : 
 ELF64: stdenv.mkDerivation
        rec {
            pname = "Zelda64Recomp";
            version = "1.0.0";
            src = fetchFromGitHub {
              owner = "Mr-Wiseguy";
              repo = "Zelda64Recomp";
              rev = "v${version}";
              deepClone = true;
              fetchSubmodules = true;
              hash = "sha256-n9wB0OSVQh3HKQgZcfSpxQ0PKJMdI4i+a4mtcYjZRdE=";
            };

            patchPhase = ''
            cp ${ELF64} ./mm.us.rev1.elf
            N64Recomp ./us.rev1.toml
            '';
            nativeBuildInputs = [cmake pkg-config SDL2 freetype shaderc xrandr gtk3 N64Recomp];
            postInstall = ''
                mkdir $out
                cp -R $src $out
            '';
        };
zelda64 =  pkgs.callPackage _zelda64 {};
in
#allMipsTools
mm majorasMaskN64