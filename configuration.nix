{ config, pkgs, inputs, ... }:

let
  # key fs should be fat32 with label "key"
  LUKSKEY_FSLABEL = "lukskey";
  KEYS_FSLABEL = "keys";
  USERNAME = "olekthunder";
in {
  imports =
    [
      ./hardware-configuration.nix
    ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 5;
  boot.loader.efi.canTouchEfiVariables = true;
  # intird modules
  boot.initrd.availableKernelModules = [
    # to mount usb with keyfile
    "uas"
    "usbcore"
    "usb_storage"
    "vfat"
    "nls_cp437"
    "nls_iso8859_1"
    # for faster io
    "aesni_intel"
    "cryptd"
  ];

  # Mount USB key before trying to decrypt root filesystem
  boot.initrd.postDeviceCommands = pkgs.lib.mkBefore ''
    mkdir -m 0755 -p /key
    sleep 2
    mount -n -t vfat -o ro `findfs LABEL=${LUKSKEY_FSLABEL}` /key
  '';
  boot.initrd.luks.devices."cryptroot" = {
    keyFile = "/key/key";
    preLVM = false; # If this is true the decryption is attempted before the postDeviceCommands can run
    # postOpenCommands = "${pkgs.umount}/bin/umount /key";
  };

  networking.hostName = "gimli";
  networking.networkmanager.enable = true;

  time.timeZone = "Europe/Kiev";

  networking.useDHCP = false;
  networking.interfaces.eno1.useDHCP = true;
  networking.interfaces.wlp0s20f3.useDHCP = true;

  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  services.xserver.enable = true;
  services.xserver.dpi = 120;
  services.xserver.windowManager.awesome.enable = true;
  services.xserver.displayManager.lightdm.enable = true;
  services.xserver.displayManager.defaultSession = "none+awesome";
  services.xserver.displayManager.autoLogin.enable = true;
  services.xserver.displayManager.autoLogin.user = USERNAME;

  services.xserver.layout = "us,ru,ua";
  services.xserver.xkbOptions = "grp:win_space_toggle";

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    config.pipewire = {
      "context.properties" = {
        "link.max-buffers" = 16; # version < 3 clients can't handle more than this
        "log.level" = 2;
      };
    };
  };
  services.xserver.libinput.enable = true;
  services.xserver.libinput.touchpad.tapping = false;

  users.users.${USERNAME} = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "audio" "docker" "video" ];
  }; 

  environment.systemPackages = with pkgs; [
    vim
    wget
    firefox
    acpi
    xclip
    git
    htop
    lsof
    alsa-utils
    unzip
  ];

  nixpkgs.config.allowUnfree = true;

  programs.light.enable = true;

  home-manager.users.${USERNAME} = { pkgs, lib, ... }: {
    home.packages = with pkgs; [
      tdesktop
      pavucontrol
      vscode
      jetbrains.pycharm-professional
      slack
      xorg.xbacklight
    ];
    home.file = {
      ".Xresources".source = "${inputs.dotfiles}/.Xresources";
    };
    xdg.configFile = {
        "awesome".source = inputs.awesome;
        # "alacritty/alacritty.yml".source = "${inputs.dotfiles}/.config/alacritty/alacritty.yml";
    };
    programs = {
      git = {
        enable = true;
        userName = USERNAME;
        userEmail = "zso040399@gmail.com";
      };
      alacritty = {
        enable = true;
        settings = {
          font = {
            normal.family = "Roboto Mono";
            size = 14;
          };
          env = {
            WINIT_X11_SCALE_FACTOR = "1.0";
          };
        };
      };
      rofi.enable = true;
    };
    services.picom = {
      enable = true;
      backend = "glx";
      vSync = true;
      inactiveDim = "0.2";
      refreshRate = 0;
      extraOptions = ''
        mark-wmwin-focused = true;
        mark-ovredir-focused = true;
        detect-client-opacity = true;
        dbe = false;
        detect-transient = true;
        detect-client-leader = true;
        glx-copy-from-front = false;
      '';
    };
    services.syncthing.enable = true;
  };

  fonts = {
    enableDefaultFonts = true;
    fontconfig = {
      enable = true;
      defaultFonts = {
        monospace = ["Roboto Mono"];
        sansSerif = ["Roboto"];
        serif = ["Roboto Slab"];
      };
    };
    fonts = with pkgs; [
      roboto
      roboto-mono
      roboto-slab
      font-awesome
      fira-code
    ];
  };
  virtualisation.docker.enable = true;
  systemd.mounts = [
    {
      what = "/dev/disk/by-label/${KEYS_FSLABEL}";
      where = "/keys";
    }
  ];
  systemd.automounts = [
    {
      where = "/keys";
      wantedBy = [ "default.target" ];
    }
  ];
  system.stateVersion = "21.05"; # Did you read the comment?
}
