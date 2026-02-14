# SOPS-Nix encrypted secrets management (age encryption).
{ inputs, user, ... }:

{
  imports = [ inputs.sops-nix.nixosModules.sops ];

  sops = {
    defaultSopsFile = ./../../secrets/secrets.yaml;
    defaultSopsFormat = "yaml";
    validateSopsFiles = true;

    age = {
      keyFile = "/home/${user}/.config/sops/age/keys.txt";
      generateKey = false;
    };

    secrets = {
      zai_api_key = {
        owner = user;
        mode = "0400";
      };
      grafana_admin_password = {
        owner = "grafana";
        mode = "0400";
      };
      ntfy_topic = {
        mode = "0444"; # DynamicUser service — no persistent user/group to grant access
      };
    };
  };
}
