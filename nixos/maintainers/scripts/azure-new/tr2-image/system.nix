{ pkgs, modulesPath, ... }:

let username = "freeswitch";
in
{
  imports = [
    "${modulesPath}/virtualisation/azure-common.nix"
    "${modulesPath}/virtualisation/azure-image.nix"
  ];

  ## NOTE: This is just an  example of how to hard-code a
  ##       user.
  ##
  ## The  normal Azure  agent  IS included  and
  ## DOES  provision   a  user  based   on  the
  ## information passed at VM creation time.
  users.users."${username}" = {
    isNormalUser = true;
    home = "/home/${username}";
    extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
  # description = "Azure NixOS Test User";
  # openssh.authorizedKeys.keys = [ (builtins.readFile ~/.ssh/id_ed25519.pub) ];
  };
  # nix.trustedUsers = [ username ];
  nix.trustedUsers = [ "@wheel" ];

  virtualisation.azureImage.diskSize = 2500;

  system.stateVersion = "20.03";
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # test user doesn't have a password
  services.openssh.passwordAuthentication = false;
  security.sudo.wheelNeedsPassword = false;

  environment.systemPackages = with pkgs; [
    git freeswitch
  ];

  services.freeswitch = {
    enable = true;

    # using `configTemplate` default (i.e., vanilla)
    # https://nixos.org/nixos/options.html#freeswitch.configtemplate

    # Should be named `overrideTemplateConfigFiles`
    # TODO add this comment to freeswitch.nix in nix.land
    # TODO homework: write function that takes an attribute set or list and evaluates it recursively
    configDir =
      # TODO Is this how to properly prefix paths? So confused:
      # https://toraritte.github.io/posts/2020-08-13-paths-vs-string-in-nix.html 
      let fs = ./tr2-image/freeswitch-vanilla-config-overrides;
      in
      # nix-repl> d = dir: a.mapAttrs' (name: value: a.nameValuePair ( dir + "/${name}" ) (value)) 
      # nix-repl> d "freeswitch" (a.recursiveUpdate { "main.xml" = 9; } (d "auto" { "pre.xml" = 1; "another.conf.xml" = 2; }))
      # { "freeswitch/auto/another.conf.xml" = 2; "freeswitch/auto/pre.xml" = 1; "freeswitch/main.xml" = 9; }
      {
        "autoload_configs/pre_load_modules.conf.xml" = fs + /
      }
    };
  };
}

# For the `configDir` option this example is given:
# 
# ```text
# {
#   "freeswitch.xml" = ./freeswitch.xml;
#   "dialplan/default.xml" = pkgs.writeText "dialplan-default.xml" ''
#     [xml lines]
#   '';
# }
# ```
# 
# How does this evaluate exactly? The first attribute's value is a local path, while the second one creates a file in the store. The way I understand it, the files in the keys will be replaced by the content of the path values.
# 
# + where does `pkgs.writeText` create the file?
# + how is the file in the template config dir substituted with the new values?
# 
# See the source of `writeText` in `<nixpkgs-root>pkgs/build-support/trivial-builders.nix` (search for `writeText =`).
