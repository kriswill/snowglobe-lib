# function to install custom program options created by mkProgramOption globally or for specified users

# programs installed by this function must have all options defined in mkProgramOption.nix to function properly
# unfortuately this means default program options from nixpkgs will have to be patched to work with it.
{ lib }:
{
  programName,
  config,
  extraModules ? { },
}:
let
  programcfg = config.programs.${programName};
  programPackage = programcfg.package;
in
lib.mkMerge [
  (lib.mkIf programcfg.installGlobally ({
    environment.systemPackages = [ programPackage ];
    programs.${programName}.installForUsers = lib.mkForce [ ];
  }))

  (lib.mkIf (programcfg.installForUsers != [ ]) {
    programs.${programName}.userPackages = (
      lib.genAttrs programcfg.installForUsers (username: lib.mkOverride 1350 programPackage)
    );
    users.users = (
      lib.genAttrs programcfg.installForUsers (
        username:
        let
          userPackage = programcfg.userPackages.${username};
        in
        {
          packages = [ userPackage ];
        }
      )
    );
  })

  extraModules

  # sanity checks
  (lib.mkIf (!programcfg.installGlobally && programcfg.installForUsers == [ ]) {
    assertions = [
      {
        assertion = false;
        message = ''
          programs.${programName} is enabled but neither has installGlobally nor installForUsers set. 
          You must set one of the options.
        '';
      }
    ];
  })
]
