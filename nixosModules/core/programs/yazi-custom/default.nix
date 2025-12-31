{
  pkgs,
  lib,
  config,
  ...
}:
let
  program-name = "yazi-custom";
  cfg = config.programs.${program-name};
in
{
  options.programs.${program-name} =
    (lib.mkProgramOption {
      description = "custom program option for yazi, allowing for custom wrapped yazi configurations";
      programName = program-name;
      packageName = "yazi";
      inherit pkgs;
    })
    // {
      zshShellWrapper = {
        enable = lib.mkOption {
          description = "whether to enable autocd zsh shell wrapper for yazi";
          type = lib.types.bool;
          default = true;
        };
        alias = lib.mkOption {
          description = "the alias to use for the zsh shell wrapper";
          type = lib.types.str;
          default = "y";
        };
      };
    };

  config = lib.mkIf cfg.enable {
    programs.yazi.enable = lib.mkOverride 0 false;
    environment.systemPackages = [
      cfg.package
    ];

    programs.zsh.promptInit = lib.mkIf cfg.zshShellWrapper.enable ''
      function ${cfg.zshShellWrapper.alias}() {
         local tmp="$(mktemp -t "yazi-cwd.XXXXX")"
         yazi "$@" --cwd-file="$tmp"
         if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
           builtin cd -- "$cwd"
         fi
         rm -f -- "$tmp"
        }
    '';
  };
}
