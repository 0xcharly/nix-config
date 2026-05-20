{ self, inputs, ... }:
{
  flake = {
    nixosModules.cloud9-host-users = {
      imports = [ inputs.home-manager.nixosModules.default ];

      home-manager = {
        users.delay = self.homeModules.cloud9-user-delay;
        useGlobalPkgs = true;
        useUserPackages = true;
      };
    };

    homeModules.cloud9-user-delay = {
      imports = with self.homeModules; [ profile-hardware-server ];
      home.stateVersion = "25.11";
    };
  };
}
