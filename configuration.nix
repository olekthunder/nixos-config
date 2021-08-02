{ config, pkgs, inputs, ... }:

let
  # key fs should be fat32 with label "key"
  KEYFSLABEL = "key";
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
    mount -n -t vfat -o ro `findfs LABEL=${KEYFSLABEL}` /key
  '';
  boot.initrd.luks.devices."cryptroot" = {
    keyFile = "/key/key";
    preLVM = false; # If this is true the decryption is attempted before the postDeviceCommands can run
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
    extraGroups = [ "wheel" "networkmanager" "audio" ];
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
  ];

  nixpkgs.config.allowUnfree = true;

  home-manager.users.${USERNAME} = { pkgs, lib, ... }: {
    home.packages = with pkgs; [
      tdesktop
      pavucontrol
      vscode
      jetbrains.pycharm-professional
      slack
      xorg.xdpyinfo
    ];
    home.file = {
      ".Xresources".source = "${inputs.dotfiles}/.Xresources";
    };
    xdg.configFile = {
        "awesome".source = inputs.awesome;
        "alacritty/alacritty.yml".source = "${inputs.dotfiles}/.config/alacritty/alacritty.yml";
    };
    programs = {
      git = {
        enable = true;
        userName = USERNAME;
        userEmail = "zso040399@gmail.com";
      };
      alacritty = {
        enable = true;
        # settings = {
        #   font = {
        #     normal.family = "JetBrainsMono Nerd Font";
        #     bold.family = "JetBrainsMono Nerd Font";
        #     italic.family = "JetBrainsMono Nerd Font";
        #     bold_italic.family = "JetBrainsMono Nerd Font";
        #     size = 14;
        #   };
        #   env = {
        #     WINIT_X11_SCALE_FACTOR = "1.0";
        #   };
        # };
      };
      rofi.enable = true;
    };
    services.picom = {
      enable = true;
      backend = "glx";
      vSync = true;
      inactiveDim = "0.2";
      extraOptions = ''
        mark-wmwin-focused = true;
        mark-ovredir-focused = true;
        detect-client-opacity = true;
        refresh-rate = 0;
        dbe = false;
        detect-transient = true;
        detect-client-leader = true;
        glx-copy-from-front = false;
      '';
    };
  };

  fonts = {
      enableDefaultFonts = true;
      fontconfig.enable = true;
      fonts = with pkgs; [
        # jetbrains-mono
        (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
      ];
    };

  system.stateVersion = "21.05"; # Did you read the comment?
}
