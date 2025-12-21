# quick and dirty declarative service config to launch an imperatively configured minecraft server
# servers must be set up with a `run.sh` containing the jvm arguments for the service to run
{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.gman.minecraft-server;

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
  options.gman.minecraft-server = {
    enable = lib.mkEnableOption "gman's minecraft-server implementation";
    config = {
      # future expansion
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
  };

  config = lib.mkIf cfg.enable {
    services.minecraft-server.enable = lib.mkForce false;

    networking.firewall.allowedTCPPorts = [ 25565 ];

    users.users.minecraft = {
      description = "Minecraft server service user";
      home = cfg.config.dataDir;
      createHome = true;
      isSystemUser = true;
      group = "minecraft";
    };
    users.groups.minecraft = { };

    # allow connection to the server console running under systemd
    programs = {
      mrpack-install.enable = lib.mkDefault true;
      mcrcon.enable = lib.mkDefault true;
    };

    # copied from nixpkgs
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
      path = [ cfg.config.javaPackage ];
      description = "Minecraft Server Service";
      wantedBy = [ "multi-user.target" ];
      requires = [ "minecraft-server.socket" ];
      after = [
        "network.target"
        "minecraft-server.socket"
      ];

      serviceConfig = {
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
