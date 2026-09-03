{ pkgs, ... }:

{
  packages = with pkgs; [
    taplo
    luau
    luau-lsp
    stylua
  ];

  enterShell = ''
    echo "Workday Progress (Noctalia v5 Plugin) Dev Environment"
    echo "Tools available: taplo, luau, luau-lsp, stylua"
  '';
}
