{
  zeldaMM ? ../baserom.mm.us.rev1.n64
}:
let 
pkgs = import <nixpkgs> {};
stdenv = pkgs.stdenv;
fetchFromGitHub = pkgs.fetchFromGitHub;
runInChroot = pkgs.callPackage ./runChroot.nix {rootfs= import ./rootfs.nix;};
in
 stdenv.mkDerivation
 {
    nativeBuildInputs = [ ];
    name = "rom2elf";
    src = fetchFromGitHub {
          owner = "zeldaret";
          repo = "mm";
          rev = "23beee0717364de43ca9a82957cc910cf818de90";
          hash = "sha256-ZhT8gaiglmSagw7htpnGEoPUesSaGAt+UYr9ujiDurE=";
          fetchSubmodules = true;
    };
    patches = [(builtins.toFile "patch" ''diff --git a/Makefile b/Makefile
index df9ceaa04..38c1ea764 100644
--- a/Makefile
+++ b/Makefile
@@ -266,7 +266,7 @@ endif
 
 .PHONY: all uncompressed compressed clean assetclean distclean assets disasm init setup
 .DEFAULT_GOAL := uncompressed
-all: uncompressed compressed
+all: uncompressed
 
 $(ROM): $(ELF)
 	$(ELF2ROM) -cic 6105 $< $@
diff --git a/tools/disasm/disasm.py b/tools/disasm/disasm.py
index 78d66d337..f97cd17e2 100755
--- a/tools/disasm/disasm.py
+++ b/tools/disasm/disasm.py
@@ -1112,7 +1112,7 @@ def asm_header(section_name: str):
 def getImmOverride(insn: rabbitizer.Instruction):
     if insn.isBranch():
         return f".L{insn.getBranchOffset() + insn.vram:08X}"
-    elif insn.isJump():
+    elif insn.isJumpWithAddress():
         return proper_name(insn.getInstrIndexAsVram(), in_data=False, is_symbol=True)
 
     elif insn.uniqueId == rabbitizer.InstrId.cpu_ori:
    '')]; 
    postPatch =  ''
      cp ${zeldaMM} baserom.mm.us.rev1.n64
    '';

    buildPhase = runInChroot ''
      make init -j8
    '';
    dontPatchELF = true;
    installPhase = ''
      mkdir -p $out
      mv mm.us.rev1.rom_uncompressed.elf $out
      mv mm.us.rev1.rom_uncompressed.z64 $out
    '';
 }