# C/C++ dev shell.
#
#   nix-shell ~/.config/shells/cpp.nix
#   cp ~/.config/shells/cpp.nix shell.nix
#
# gcc and gnumake used to sit in environment.systemPackages with nothing on the
# machine calling them. stdenv provides both here, scoped to the project.
{ pkgs ? import <nixpkgs> { } }:

pkgs.mkShell {
  # gcc/g++/ld/make come from stdenv. Listing pkgs.gcc explicitly would shadow
  # the wrapper and drop the NixOS include/lib paths.
  packages = with pkgs; [
    cmake
    ninja
    pkg-config
    clang-tools # clangd, clang-format, clang-tidy.
    gdb
  ];

  # clangd reads compile_commands.json; without it every #include of a nix-store
  # header is flagged as missing.
  shellHook = ''
    export CMAKE_EXPORT_COMPILE_COMMANDS=1
  '';
}
