{
  description = "Example nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-25-11.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nix-darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    niri-screen-time.url = "github:probeldev/niri-screen-time";
    fastlauncher.url = "github:fastlauncher/fastlauncher";
    fastlauncher_next.url = "github:fastlauncher/fastlauncher_next";
    sqlit.url = "github:Maxteabag/sqlit";

    # свежий rift напрямую из исходников, не дожидаясь nixpkgs-unstable
    rift.url = "github:acsandmann/rift";
    rift.flake = false;
  };

  outputs = inputs@{
    self,
    nix-darwin,
    nixpkgs,
    nixpkgs-25-11,
    nixpkgs-unstable,
    niri-screen-time,
    fastlauncher,
    fastlauncher_next,
    sqlit,
    rift,
  }:
  let
    configuration = { pkgs, ... }:
    let
      pkgs-25-11 = import nixpkgs-25-11 {
        system = pkgs.system;
        config = {
          allowUnfree = true;
          permittedInsecurePackages = [
            "python3.12-ecdsa-0.19.1"
          ];
        };
      };
      pkgs-unstable = import nixpkgs-unstable {
        system = pkgs.system;
        config.allowUnfree = true;
      };

      # rift-wm из nixpkgs-unstable, но с src = последний master acsandmann/rift
      rift-latest =
        let
          rev = rift.shortRev or "dirty";
        in
        pkgs-unstable.rift-wm.overrideAttrs (old: {
          version = "git-${rev}";
          src = rift;
          cargoDeps = pkgs-unstable.rustPlatform.fetchCargoVendor {
            pname = old.pname;
            version = "git-${rev}";
            src = rift;
            # TODO: после первой сборки заменить на хеш из ошибки "hash mismatch"
            hash = "sha256-wxymypJjczFqI9oivnVX/TOnR1KuupsaryQIQQVN7Gs=";
          };
        });
    in
    {
      # List packages installed in system profile. To search by name, run:
      # $ nix-env -qaP | grep wget

      nix.enable = false;
      nixpkgs.config.allowUnfree = true;
      nixpkgs.config.permittedInsecurePackages = [
        "python3.12-ecdsa-0.19.1"
      ];

      # darwin-rebuild без пароля (NOPASSWD), чтобы его могли запускать агенты и скрипты
      security.sudo.extraConfig = ''
        sergey ALL=(ALL) NOPASSWD: /run/current-system/sw/bin/darwin-rebuild
      '';

      environment.systemPackages = with pkgs; [
        superfile
        yazi

        vim
        neovim
        telegram-desktop
        dbgate
        fzf
        skim # rust alternative fzf
        ripgrep
        btop
        lazygit
        tree

        sqlit.packages.${pkgs.system}.default

        whisky

        go
        gopls
        gotools
        golangci-lint
        vtsls
        prettier
        zig

        orbstack

        ffmpeg
        imagemagick

        cargo
        rust-analyzer
        rustfmt

        rio

        nmap

        zed-editor

        fastfetch

        google-chrome

        pkgs-25-11.renpy

        pkgs-unstable.ollama
        pkgs-unstable.opencode
        pkgs-unstable.pi-coding-agent
        pkgs-unstable.rtk
        python313Packages.mlx-vlm

        zellij

        niri-screen-time.packages.${pkgs.system}.default
        fastlauncher.packages.${pkgs.system}.default
        fastlauncher_next.packages.${pkgs.system}.default

        starship

        # unixporn
        # aerospace
        rift-latest
        skhd
        jankyborders

        sshuttle

        firefox

        lima

        ## md2pdf

        transmission_4-qt6
      ];

      fonts.packages = with pkgs; [
        nerd-fonts.fira-code
      ];

      # Necessary for using flakes on this system.
      nix.settings.experimental-features = "nix-command flakes";

      # Enable alternative shell support in nix-darwin.
      # programs.fish.enable = true;

      # Set Git commit hash for darwin-version.
      system.configurationRevision = self.rev or self.dirtyRev or null;

      # Used for backwards compatibility, please read the changelog before changing.
      # $ darwin-rebuild changelog
      system.stateVersion = 6;

      # The platform the configuration will be used on.
      nixpkgs.hostPlatform = "aarch64-darwin";
    };
  in
  {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#Sergeys-MacBook-Air
    darwinConfigurations."Sergeys-MacBook-Air" = nix-darwin.lib.darwinSystem {
      modules = [ configuration ];
    };
  };
}
