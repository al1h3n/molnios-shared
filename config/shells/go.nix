# Go dev shell.
#
#   nix-shell ~/.config/shells/go.nix
#   cp ~/.config/shells/go.nix shell.nix
{ pkgs ? import <nixpkgs> { } }:

pkgs.mkShell {
  packages = with pkgs; [
    go
    gopls
    gofumpt
    delve         # Debugger.
    golangci-lint
  ];

  # Keep module/build caches inside the project instead of ~/go, so deleting
  # the checkout actually reclaims the space.
  shellHook = ''
    export GOPATH="$PWD/.go"
    export GOBIN="$GOPATH/bin"
    export PATH="$GOBIN:$PATH"
  '';
}
