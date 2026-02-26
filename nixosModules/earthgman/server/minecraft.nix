# quick and dirty declarative service config to launch an imperatively configured minecraft server
# servers must be set up with a `run.sh` containing the jvm arguments for the service to run
{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.earthgman.minecraft-server;

  stopScript = pkgs.writeShellScript "minecraft-server-stop" ''
    echo stop > ${config.systemd.sockets.minecraft-server.socketConfig.ListenFIFO}

    # Wait for the PID of the minecraft server to disappear before
    # returning, so systemd doesn't attempt to SIGKILL it.
    while kill -0 "$1" 2> /dev/null; do
      sleep 1s
    done
  '';
in
{
  options.earthgman.minecraft-server = {
    enable = lib.mkEnableOption "EarthGman's configuration for a minecraft server";
    # TODO future expansion, allow multiple servers on one machine?
    # name = lib.mkOption {
    #   description = "name of the minecraft server";
    #   type = lib.types.str;
    #   default = "server";
    # };
    javaPackage = lib.mkOption {
      description = "java package used to start the server";
      type = lib.types.package;
      default = pkgs.jre;
    };

    dataDir = lib.mkOption {
      description = "directory on the filesystem where the server is stored";
      type = lib.types.str;
      default = "/srv/minecraft";
    };
  };

  config = lib.mkIf cfg.enable {
    # Disable the default minecraft server
    services.minecraft-server.enable = lib.mkOverride 0 false;

    # allow the minecraft port
    # if using rcon from a remote machine, port 25575 will also need to opened
    # assume default port and just use network routing to differ servers on the same lan
    networking.firewall.allowedTCPPorts = [ 25565 ];

    programs = {
      # install modpacks from modrinth
      mrpack-install.enable = lib.mkDefault true;
      # allow connection to the server console running under systemd
      mcrcon.enable = lib.mkDefault true;
    };

    # copied from nixpkgs
    users.users.minecraft = {
      description = "Minecraft server service user";
      home = cfg.config.dataDir;
      createHome = true;
      isSystemUser = true;
      group = "minecraft";
    };
    users.groups.minecraft = { };

    systemd.sockets.minecraft-server = {
      bindsTo = [ "minecraft-server.service" ];
      socketConfig = {
        ListenFIFO = "/run/minecraft-server.stdin";
        SocketMode = "0660";
        SocketUser = "minecraft";
        SocketGroup = "minecraft";
        RemoveOnStop = true;
        FlushPending = true;
      };
    };

    systemd.services.minecraft-server = {
      # provide javaPackage to the service path so it can call `java -jar` from run.sh using a specific version
      path = [ cfg.config.javaPackage ];
      description = "Minecraft Server Service";
      wantedBy = [ "multi-user.target" ];
      requires = [ "minecraft-server.socket" ];
      after = [
        "network.target"
        "minecraft-server.socket"
      ];

      serviceConfig = {
        # most server setup tools create a `run.sh` so just hardcode it lol
        ExecStart = "${cfg.config.dataDir}/run.sh";
        ExecStop = "${stopScript} $MAINPID";
        Restart = "on-failure";
        RestartSec = 15;
        User = "minecraft";
        WorkingDirectory = cfg.config.dataDir;

        StandardInput = "socket";
        StandardOutput = "journal";
        StandardError = "journal";

        # Hardening
        CapabilityBoundingSet = [ "" ];
        DeviceAllow = [ "" ];
        LockPersonality = true;
        PrivateDevices = true;
        PrivateTmp = true;
        PrivateUsers = true;
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectHome = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectProc = "invisible";
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
        ];
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        SystemCallArchitectures = "native";
        UMask = "0077";
      };
    };
  };
}
