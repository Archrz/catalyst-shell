{
  pkgs,
  lib,
  username,
  variables,
  ...
}:
let
  # paths
  configHome = "/home/${username}/.config";
  cacheHome = "/home/${username}/.cache";
  homeDir = "/home/${username}";
  qsRoot = "${configHome}/quickshell/catalyst";
  wallpaperDir = variables.wallpaperDir or "${homeDir}/catalyst/home/arch/wall";
  shellLog = "${cacheHome}/catalyst/shell.log";

  quickshell = lib.getExe pkgs.quickshell;

  catalystQsSource = lib.cleanSourceWith {
    src = ./.;
    filter = path: _type: !lib.hasSuffix "default.nix" (toString path);
  };

  # shell wrapper scripts
  writeBin = pkgs.writeShellScriptBin;

  prepareShellLog = ''
    mkdir -p "$(dirname "${shellLog}")"
    : >"${shellLog}"
  '';

  showShellLogs = ''
    sleep 0.5
    cat "${shellLog}"
  '';

  mkIpc =
    name: call:
    writeBin name ''
      exec ${quickshell} -c ${qsRoot} ipc call ${call}
    '';

  screenshareChooser = writeBin "catalyst-screenshare-chooser" ''
    f=$(mktemp)
    trap 'rm -f "$f"' EXIT
    cat > "$f"
    A="$f" ${quickshell} -p ${qsRoot}/screenshare.qml > /dev/null
    cat "$f"
  '';

  ipcBins = [
    (mkIpc "catalyst-launcher" "launcher toggle")
    (mkIpc "catalyst-clipboard" "launcher openClipboard")
    (mkIpc "catalyst-dashboard" "dashboard toggle")
    (mkIpc "catalyst-screenshot" "screenshot capture")
    (mkIpc "catalyst-screenshot-save" "screenshot captureSave")
    (mkIpc "catalyst-markup" "screenshot captureMarkup")
    (mkIpc "catalyst-idle" "idle trigger")
    (mkIpc "catalyst-colorpicker" "colorpicker pick")
  ];
in
{
  home-manager.users.${username} = {
    programs.waybar.enable = lib.mkForce false;

    systemd.user.services.catalyst-shell = {
      Unit = {
        Description = "Catalyst quickshell bar and overlays";
        PartOf = "graphical-session.target";
        After = "graphical-session.target";
        ConditionEnvironment = "XDG_CURRENT_DESKTOP=mango";
      };
      Service = {
        Type = "simple";
        KillMode = "process";
        ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p ${cacheHome}/catalyst";
        ExecStart = "${quickshell} -c ${qsRoot}";
        StandardOutput = "append:${shellLog}";
        StandardError = "append:${shellLog}";
        Restart = "on-failure";
        RestartSec = "1s";
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };

    home.packages = [
      pkgs.quickshell
      pkgs.awww
      pkgs.mpvpaper
      pkgs.zenity
      pkgs.cliphist
      pkgs.grim
      pkgs.wl-clipboard
      (writeBin "catalyst-shell" ''
        ${prepareShellLog}
        systemctl --user reset-failed catalyst-shell.service
        systemctl --user start catalyst-shell.service
        ${showShellLogs}
      '')
      (writeBin "catalyst-shell-restart" ''
        catalyst-shell-stop
        catalyst-shell
      '')
      (writeBin "catalyst-shell-stop" ''
        systemctl --user stop catalyst-shell.service
      '')
      (writeBin "catalyst-lock" ''
        exec ${quickshell} -p ${qsRoot}/lockscreen
      '')
      screenshareChooser
    ]
    ++ ipcBins;

    home.sessionVariables = {
      QT_QUICK_CONTROLS_STYLE = lib.mkDefault "Basic";
      CATALYST_WALLPAPER_DIR = wallpaperDir;
    };

    xdg.configFile."quickshell/catalyst".source = catalystQsSource;
  };
}
