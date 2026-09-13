# Rust dev shell.
#
#   nix-shell ~/.config/shells/rust.nix     # one-off
#   cp ~/.config/shells/rust.nix shell.nix  # per-project, fish auto-enters it
#
# cargo, rustc and a linker are deliberately NOT in the system profile - they
# have no users outside a project checkout.
{ pkgs ? import <nixpkgs> { } }:

pkgs.mkShell {
  # mkShell already pulls in stdenv, so cc/ld/make are on PATH. Listing gcc
  # here would shadow the wrapped compiler and break linking.
  packages = with pkgs; [
    cargo
    rustc
    rustfmt
    clippy
    rust-analyzer

    pkg-config # Almost every crate with a -sys dependency needs it.
  ];

  # rust-analyzer resolves std:: through this. Without it every symbol from
  # core/std reports "no definition found" and it looks like the LSP is broken.
  RUST_SRC_PATH = "${pkgs.rustPlatform.rustLibSrc}";
}
