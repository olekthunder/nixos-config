# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

let
  # key fs should be fat32 with label "key"
  KEYFSLABEL = "key";
  USERNAME = "olekthunder";
in {
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
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

  networking.hostName = "gimli"; # Define your hostname.
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Kiev";

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.eno1.useDHCP = true;
  networking.interfaces.wlp0s20f3.useDHCP = true;
  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  services.xserver.windowManager.awesome.enable = true;
  services.xserver.displayManager.lightdm.enable = true;
  services.xserver.displayManager.defaultSession = "none+awesome";
  services.xserver.displayManager.autoLogin.enable = true;
  services.xserver.displayManager.autoLogin.user = USERNAME;

  # Configure keymap in X11
  services.xserver.layout = "us,ru,ua";
  services.xserver.xkbOptions = "grp:win_space_toggle";

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    config.pipewire = {
      "context.properties" = {
        #"link.max-buffers" = 64;
        "link.max-buffers" = 16; # version < 3 clients can't handle more than this
        "log.level" = 2; # https://docs.pipewire.org/#Logging
        #"default.clock.rate" = 48000;
        #"default.clock.quantum" = 1024;
        #"default.clock.min-quantum" = 32;
        #"default.clock.max-quantum" = 8192;
      };
    };
  };
  # Enable touchpad support (enabled default in most desktopManager).
  services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.${USERNAME} = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "audio" ];
  }; 

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    firefox
    acpi
    xclip
    git
    htop
    lsof
    alsa-utils
  ];

  home-manager.users.${USERNAME} = { pkgs, lib, ... }: {
    home.packages = with pkgs; [
      tdesktop
      pavucontrol
    ];

    programs = {
      git = {
        enable = true;
        userName = USERNAME;
        userEmail = "zso040399@gmail.com";
      };
      alacritty.enable = true;
    };
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.05"; # Did you read the comment?

}
