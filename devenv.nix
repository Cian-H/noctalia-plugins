{ pkgs, ... }:

{
  packages = with pkgs; [
    taplo
    luau
    luau-lsp
    stylua
  ];

  enterShell = ''
    echo "Cian-H's Noctalia Plugins Repository Dev Environment"
    echo "Tools: taplo, luau, luau-lsp, stylua"
  '';
}
