# Python dev shell.
#
#   nix-shell ~/.config/shells/python.nix
#   cp ~/.config/shells/python.nix shell.nix
#
# Replaces the old global pipx: uv creates a real per-project venv instead of
# scattering app venvs in ~/.local/share/pipx.
#
#   uv venv && uv pip install -r requirements.txt
#   uv tool install <app>     # what pipx did
{ pkgs ? import <nixpkgs> { } }:

pkgs.mkShell {
  packages = with pkgs; [
    # Add libraries here for anything with a C extension that uv cannot build:
    #   (python3.withPackages (ps: with ps; [ numpy requests ]))
    python3
    uv
    ruff         # Linter + formatter.
    basedpyright # LSP.
  ];

  # uv downloads manylinux wheels that are not patchelf'd for NixOS. Point them
  # at the nix-ld library set instead of letting them fail on missing libstdc++.
  shellHook = ''
    export UV_PYTHON_PREFERENCE=only-system
    export LD_LIBRARY_PATH="${pkgs.lib.makeLibraryPath [ pkgs.stdenv.cc.cc.lib pkgs.zlib ]}:$LD_LIBRARY_PATH"
  '';
}
