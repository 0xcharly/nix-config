{
  lib,
  pkgs,
  ...
} @ args: let
  config =
    if args ? osConfig
    then args.osConfig
    else args.config;
  inherit (pkgs.stdenv) isDarwin isLinux;
  inherit (config.modules.usrenv) isCorpManaged isHeadless;

  inherit (config.modules.system.hosts) asl;
in {
  programs.ssh = let
    # NOTE: most SSH servers use the default limit of 6 keys for authentication.
    # Once the server limit is reached, authentication will fail with "too many
    # authentication failures". reached, authentication will fail with "
    _1passwordAgentPathMacOS = "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock";
    _1passwordAgentOrKey = key:
      lib.optionalAttrs isDarwin {IdentityAgent = "\"${_1passwordAgentPathMacOS}\"";}
      // lib.optionalAttrs (isLinux && !isHeadless) {IdentityFile = "~/.ssh/${key}";};
  in {
    enable = true;
    matchBlocks =
      {
        # Personal hosts.
        "bitbucket.org" = {
          user = "git";
          extraOptions = _1passwordAgentOrKey "bitbucket";
        };
        "github.com" = {
          user = "git";
          extraOptions = _1passwordAgentOrKey "github";
        };
        "linode" = {
          hostname = "172.105.192.143";
          extraOptions = _1passwordAgentOrKey "linode";
          forwardAgent = true;
        };
      }
      // (lib.optionalAttrs (isDarwin && !isCorpManaged) {
        # Home storage host.
        "skullkid.local" = {
          hostname = "192.168.86.43";
          extraOptions = _1passwordAgentOrKey "skullkid";
          forwardAgent = true;
        };
        # VMWare hosts.
        "192.168.*" = {
          extraOptions = _1passwordAgentOrKey "vm";
        };
        # ASL host.
        "asl" = {
          hostname = asl.networking.address;
          extraOptions = _1passwordAgentOrKey "vm";
          forwardAgent = true;
        };
      });
    userKnownHostsFile = "~/.ssh/known_hosts ~/.ssh/known_hosts.trusted";
  };

  # Install known SSH keys for trusted hosts.
  home.file.".ssh/known_hosts.trusted".text = ''
    172.105.192.143 ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBDKudRpK8c+opPGokE2f5Z7gd2yWTHRrA6p3/YayieSRTDOnmb4aR1Pmbz967KBeo+KYm+4R/d59p4mABKPztNU=
    172.105.192.143 ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE/xP/0LQP88FKB3cQKuMvHCj53UiAMnV3rZFQiMsLkV
    172.105.192.143 ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDR76lteEphRkj6ifIQbd8T7XjzsALnIt51kptcR40e6TcHzn2/0ptqRbadad5sDKQ8lZJmUX+Sz6FM1o7M8zKnoxs7HkjnjvK0Tj/19O1PJ88eygKhlFjFeLyV17Ib+zKD3IYcQcalv701FU2CFV+WV5o/RUIh1SQX69g4H+iiBXinT3NNLTNnCq3+2epU0vxbrsLNUGfvjfRGB2GVE4Tj2CzDrwu+wz1LaHKeMC60jUfdrjbzpTg4EJixm42QsU2RNTc4w+hNHcuRtgd8WG/FryQEW1P+v7hUxbxwhorevYPmQevl59UTW5WtvQvkTUl2SaezSpOpk0vTktJhVsiQOcCnp2I1dD7kthucn2ar5VbAIcD+q3bJJAUXyrJKFSj4t5G7jNcdTJjVcD/rCoY5oDkIHpIyFoVlueKkrczYW/LV4xXj9Psfdg0oEstjEupVsMkzqSBXmWJ2JkAJHlHwSc87ofPjuVSUqdr+iA1d5KNmE+JqdL0JqHDVIbdhlqU=
    192.168.86.43 ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBHiIQCyO9THWqAxDtfS/QixESfaAC2kXOCjYHTR9oDhuWCX5gvR2zCqYGMfZiQOFrE+am2kqSIheZ0HABxTRZmQ=
    192.168.86.43 ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICT2Px+IB0pL69ctFv1SesgFD3gfTHw9SibG5FpITj9u
    192.168.86.43 ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQD0+m8i3AltBVajoem4XioRqXnTF7WsQMm7w4zlYxw0lCYIwyvhoMKO46E8f4MP6qCRHzvWKMpqsGOy5gKpva0/VtSYyvDXH8BhMr4sf/g30Dz8zY+CVPhLKYVbZD9ZasrD66CkqYSVLb0yqHD70D8NPEzqDW/hfJLF7NUMqhG9HkIMroo6weAHjHdIRyu4nvGOId1/wSNY0i1epxLkqkqMQt3Qp1oYGVAfQyKynJ0tRfarf1VJcn7b5XpV5g+xF7uhXIIdCuGC8vDW9SZ0RUar8qP2B1ooiH9IBtEFpWKRA6rXUsWrisQJFIRljjKYrBQm8zIfxIkscuXBlkoMfhFI7CLa38mk/ADnJIkHXfcre3Zg/TPYln1HLu08doUkjRZLWojRuxDQfjmUHtGfix7hAJbEVEx74vCBNIqsCPLdq1ToBXB2QUOSXn5Mx6zRJVcQzLXIYllRaywIxH4+fanMGVslV5hnos7DlhJyngH2wnUS3XsAhH7Hikl2zEGymXM=
    bitbucket.org ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBPIQmuzMBuKdWeF4+a2sjSSpBK0iqitSQ+5BM9KhpexuGt20JpTVM7u5BDZngncgrqDMbWdxMWWOGtZ9UgbqgZE=
    bitbucket.org ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIazEu89wgQZ4bqs3d63QSMzYVa0MuJ2e2gKTKqu+UUO
    bitbucket.org ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDQeJzhupRu0u0cdegZIa8e86EG2qOCsIsD1Xw0xSeiPDlCr7kq97NLmMbpKTX6Esc30NuoqEEHCuc7yWtwp8dI76EEEB1VqY9QJq6vk+aySyboD5QF61I/1WeTwu+deCbgKMGbUijeXhtfbxSxm6JwGrXrhBdofTsbKRUsrN1WoNgUa8uqN1Vx6WAJw1JHPhglEGGHea6QICwJOAr/6mrui/oB7pkaWKHj3z7d1IC4KWLtY47elvjbaTlkN04Kc/5LFEirorGYVbt15kAUlqGM65pk6ZBxtaO3+30LVlORZkxOh+LKL/BvbZ/iRNhItLqNyieoQj/uh/7Iv4uyH/cV/0b4WDSd3DptigWq84lJubb9t/DnZlrJazxyDCulTmKdOR7vs9gMTo+uoIrPSb8ScTtvw65+odKAlBj59dhnVp9zd7QUojOpXlL62Aw56U4oO+FALuevvMjiWeavKhJqlR7i5n9srYcrNV7ttmDw7kf/97P5zauIhxcjX+xHv4M=
    github.com ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBEmKSENjQEezOmxkZMy7opKgwFB9nkt5YRrYMjNuG5N87uRgg6CLrbo5wAdT/y6v0mKV0U2w0WZ2YB/++Tpockg=
    github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl
    github.com ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCj7ndNxQowgcQnjshcLrqPEiiphnt+VTTvDP6mHBL9j1aNUkY4Ue1gvwnGLVlOhGeYrnZaMgRK6+PKCUXaDbC7qtbW8gIkhL7aGCsOr/C56SJMy/BCZfxd1nWzAOxSDPgVsmerOBYfNqltV9/hWCqBywINIR+5dIg6JTJ72pcEpEjcYgXkE2YEFXV1JHnsKgbLWNlhScqb2UmyRkQyytRLtL+38TGxkxCflmO+5Z8CSSNY7GidjMIZ7Q4zMjA2n1nGrlTDkzwDCsw+wqFPGQA179cnfGWOWRVruj16z6XyvxvjJwbz0wQZ75XK5tKSb7FNyeIEs4TT4jk+S4dhPeAUC5y+bDYirYgM4GC7uEnztnZyaVWQ7B381AK4Qdrwt51ZqExKbQpTUNn+EjqoTwvqNj4kqx5QUCI0ThS/YkOxJCXmPUWZbhjpCg56i+2aB6CmK2JGhn57K5mj0MNdBXA4/WnwH6XoPWJzK5Nyu2zB3nAZp+S5hpQs+p1vN1/wsjk=
  '';
}
