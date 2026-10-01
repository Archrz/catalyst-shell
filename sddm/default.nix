{
  pkgs,
  config,
  lib,
  username,
  variables,
  ...
}:
let
  themeName = "catalyst-sddm";

  wallpaperDir = variables.wallpaperDir or "/home/${username}/catalyst/home/arch/wall";

  catalystTheme = pkgs.runCommand "${themeName}-theme" { } ''
    mkdir -p $out/share/sddm/themes/${themeName}
    cp -a ${./.}/. $out/share/sddm/themes/${themeName}/
    chmod -R u+w $out/share/sddm/themes/${themeName}
    rm -f $out/share/sddm/themes/${themeName}/default.nix
  '';
in

lib.mkIf config.services.displayManager.sddm.enable {
  system.activationScripts.sddmClearQmlCache = lib.stringAfter [ "specialfs" ] ''
    for d in /var/cache/sddm /var/lib/sddm/.cache; do
      if [ -d "$d" ]; then
        echo "clearing SDDM QML cache: $d"
        find "$d" -mindepth 1 -delete 2>/dev/null || true
      fi
    done
  '';

  services.displayManager.sddm = {
    extraPackages = [
      catalystTheme
      pkgs.nerd-fonts.jetbrains-mono
    ];
    wayland.enable = true;

    theme = themeName;

    settings = {
      General.GreeterEnvironment = "QT_AUTO_SCREEN_SCALE_FACTOR=0 QT_SCALE_FACTOR=1 XCURSOR_THEME=Adwaita XCURSOR_SIZE=24";
    };
  };

  systemd.tmpfiles.rules = [ "d /var/lib/sddm-wallpaper 1777 root root -" ];

  system.activationScripts.sddmSeedWallpaper = lib.stringAfter [ "specialfs" ] ''
    if [ ! -e /var/lib/sddm-wallpaper/current ] && [ -f "${wallpaperDir}/1.png" ]; then
      mkdir -p /var/lib/sddm-wallpaper
      cp -f "${wallpaperDir}/1.png" /var/lib/sddm-wallpaper/current
    fi
  '';

  environment.systemPackages = [ catalystTheme ];
}
