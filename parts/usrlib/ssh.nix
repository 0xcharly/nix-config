{lib, ...}: let
  knownHosts = {
    "bitbucket.org" = {
      ecdsa-sha2-nistp256 = "AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBPIQmuzMBuKdWeF4+a2sjSSpBK0iqitSQ+5BM9KhpexuGt20JpTVM7u5BDZngncgrqDMbWdxMWWOGtZ9UgbqgZE=";
      ssh-ed25519 = "AAAAC3NzaC1lZDI1NTE5AAAAIIazEu89wgQZ4bqs3d63QSMzYVa0MuJ2e2gKTKqu+UUO";
      ssh-rsa = "AAAAB3NzaC1yc2EAAAADAQABAAABgQDQeJzhupRu0u0cdegZIa8e86EG2qOCsIsD1Xw0xSeiPDlCr7kq97NLmMbpKTX6Esc30NuoqEEHCuc7yWtwp8dI76EEEB1VqY9QJq6vk+aySyboD5QF61I/1WeTwu+deCbgKMGbUijeXhtfbxSxm6JwGrXrhBdofTsbKRUsrN1WoNgUa8uqN1Vx6WAJw1JHPhglEGGHea6QICwJOAr/6mrui/oB7pkaWKHj3z7d1IC4KWLtY47elvjbaTlkN04Kc/5LFEirorGYVbt15kAUlqGM65pk6ZBxtaO3+30LVlORZkxOh+LKL/BvbZ/iRNhItLqNyieoQj/uh/7Iv4uyH/cV/0b4WDSd3DptigWq84lJubb9t/DnZlrJazxyDCulTmKdOR7vs9gMTo+uoIrPSb8ScTtvw65+odKAlBj59dhnVp9zd7QUojOpXlL62Aw56U4oO+FALuevvMjiWeavKhJqlR7i5n9srYcrNV7ttmDw7kf/97P5zauIhxcjX+xHv4M=";
    };
    "github.com" = {
      ecdsa-sha2-nistp256 = "AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBEmKSENjQEezOmxkZMy7opKgwFB9nkt5YRrYMjNuG5N87uRgg6CLrbo5wAdT/y6v0mKV0U2w0WZ2YB/++Tpockg=";
      ssh-ed25519 = "AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl";
      ssh-rsa = "AAAAB3NzaC1yc2EAAAADAQABAAABgQCj7ndNxQowgcQnjshcLrqPEiiphnt+VTTvDP6mHBL9j1aNUkY4Ue1gvwnGLVlOhGeYrnZaMgRK6+PKCUXaDbC7qtbW8gIkhL7aGCsOr/C56SJMy/BCZfxd1nWzAOxSDPgVsmerOBYfNqltV9/hWCqBywINIR+5dIg6JTJ72pcEpEjcYgXkE2YEFXV1JHnsKgbLWNlhScqb2UmyRkQyytRLtL+38TGxkxCflmO+5Z8CSSNY7GidjMIZ7Q4zMjA2n1nGrlTDkzwDCsw+wqFPGQA179cnfGWOWRVruj16z6XyvxvjJwbz0wQZ75XK5tKSb7FNyeIEs4TT4jk+S4dhPeAUC5y+bDYirYgM4GC7uEnztnZyaVWQ7B381AK4Qdrwt51ZqExKbQpTUNn+EjqoTwvqNj4kqx5QUCI0ThS/YkOxJCXmPUWZbhjpCg56i+2aB6CmK2JGhn57K5mj0MNdBXA4/WnwH6XoPWJzK5Nyu2zB3nAZp+S5hpQs+p1vN1/wsjk=";
    };
  };
  tailscaleKnownHosts = {
    # Gen 2 NAS hosts.
    bowmore.ssh-ed25519 = "AAAAC3NzaC1lZDI1NTE5AAAAIBc7+svM9KE66X8lpQzYny0byI47Kr38LsYXVyJIZd+w";
    dalmore.ssh-ed25519 = "AAAAC3NzaC1lZDI1NTE5AAAAIPEQB+CwUB/zGI76uwH95mhwnhvHQKw1/J08ioDzw+W/";
    laphroaig.ssh-ed25519 = "AAAAC3NzaC1lZDI1NTE5AAAAIOOGCAJVRToabx32L6jIUdzDhU43QWa6dXm4sAN/H96m";
    talisker.ssh-ed25519 = "AAAAC3NzaC1lZDI1NTE5AAAAIHsn07q7SmdP1M09ZIrz0bD9Te+5OMVVlfGEtAP9+iP9";

    "heimdall" = {
      ssh-ed25519 = "AAAAC3NzaC1lZDI1NTE5AAAAIOBffqWJu60tEBRH9t7aA/Za9BHPghKRt+Ihaie60YTf";
      ssh-rsa = "AAAAB3NzaC1yc2EAAAADAQABAAACAQDmrInYDqQ1w3PCVTmavg95gAo2h73ybn1L73wwr7ijWFHI9K95M33OeQzTN84Mgt6v5QzejmgTAnyqTYGmxqzHUEJ6K5MXKxz6BawDvZy40n7Y3D6NnQTllxvPRrBurD0FVULqORB5Ls/L4eExQbAKZuHUm+PNLkc9t+uxMQFPnGO5mu+fAJLajCnXRtw/YAOSFQ66PaZNVAQMaXUTK8WGwgbanfpYbiyeUhnQTQe+ulrfYikXgS7X2M/l7I08JcMhqzSWzh6iTtxZvR8DRdCEd8TJddZrAlQIrjurhk3LccDjSiwi6I35AQQjl+MNSJKH/hes6ECL799NEuT556ZGTuCTmHAKTa2J9EWxAefspUDnIlSBv4O826f+1yEo6erw6tEWBxG1XR7QSVGt+K9W82GpoFmB3iMq51Ympw6TIqM+gM/YtIXVLY3LOjH2cGAw7CDP5k9FeBRqVO4+YdLTXm6/s1LeRJMnGUkuerQdo3g96WeYTKt1TICFCDUqrl14gxfIX8+71Sbi5RrNg2tX00yyN+XTz0iYUmvxj3z/CRKq/NbeOBT2P0GNE6VVJ1oQuZct4q4BhhuWQUMegpS7X46ZhKGa3E37SekiTLKOtxE9dD+6XP8eB6EaZksC+zDQVHDgROGZUi8gR0eDjwQTEOa6OhIr0Wa6mi3l3AhHDQ==";
    };
    "linode" = {
      ssh-ed25519 = "AAAAC3NzaC1lZDI1NTE5AAAAIMVouzrCM9iNkhf3E7yOGPggY6xeBmjfKnwymsSBQ/Af";
      ssh-rsa = "AAAAB3NzaC1yc2EAAAADAQABAAACAQC7QcBkDyoEq57lbAmigUjjfcmbDImHxRZC6h6nEl2ddgNBfDn/PnnU2s1VuzyZggWQPIc+FyHBcodBGP0sy2w8lv9ikqsivhWG6EO+Bj1qefxgU8sxIZ1imFP2nIwUDLUv5Gv5UEexOVQ/DxPgHLRvAqTUiNeu4/aaViG/8AHmPrIxS+zxeYjwg3+v4b0Yf87dUukfkxSLAsxL1vlMSTaNpBqLGNUI4FCLA1Ne95bXlBvY3KM8vDr0SilU8eBkJshn5tgbPnjGgbO3VPAxYp7f76dMJJcsQ5C3pWDAuPQZwpRKnT/ghU7NOXK2Mfo14VMS+FDKfVOkcpvBSRvgE9N+2RHRDdTvWJDSOi5p9Pb/khwlWU5fBz5GXwieFaAyPc2eAw+fA9gZlq6szxTy63yljMNem/koziIgeYnSV9Jqw9E6tdkWzsfSncNI/NewkmyDMFcTQ6dw+dca1OAne0GSiQU3OyG4sjDWvPZUF1L+4ymM3pr7beTsJP5e98LoJWpdzCmr/eyeSBxQwA3cMOGNWfBxMVh25FhqBktJ3NgwGAAGGQRNHqdMSZuFe7sC6AFKMSi3SB4zMXvDhl4vxKTNFNSo0/L7QdoloHlmq/Iz3SmzC7Aq9n/JDpFF6EzRO518YJ6AiXzcXw/CaizZratlTiQVrZWwgnPK/mic1XF2aQ==";
    };
    "nyx" = {
      ssh-ed25519 = "AAAAC3NzaC1lZDI1NTE5AAAAIJmofQEhKZ7TOhqDMBwBr/p7ffOq2caH43ea1w/AsKoS";
      ssh-rsa = "AAAAB3NzaC1yc2EAAAADAQABAAACAQCN42MTL5EUXBc8OEKp3ddH4D7jQe1RYo4l2MFtfsgg3J1KNndRo4ym/VVY5HZKJ3Fk5TqPFbwOP4v8ZcmFK57SuzyyMfzh/2kD8XTGnPJSkwTcTsr9rRuxXus8rQ0Srn2gLi0ai64c5jWcPTne+ZpD/0dA/Xkp+g48Ftvd5DNFGTqY5rAQ5cnRIebt/XNfiCwQ1Y57/q5pwI1A1pCl5X5uk938INv210VdQe2aHa8vL3hbtDkCehC92ST24YDeYKE74BtPN9mAAfXc5vgfoCHaEUnRZNz+ZoGJ+Gvs4V3U9DacrrLKHjpMwoNc/U6d2lvP5q8Xej6pPpf9EbGXMqxjQfgPvYyQ3nxco8prZAYVUOmxUH1rNBCUB4PoUeXW1KvaxZ8Jy+7wED/6WmobggY+CyeWM6VmLIt/WqMBIFolnGOay2dNFN4SSku1lOj5iJzOUIR7JvRzsW4p5yvlIoIgrmKRLiFwZ0BEK9aQhvu+anhjdiXv+DLAhOzV0Cfr0rsY0jQyF2bbB0lBfyZkwDaGkiYrFo/Zi831DTu9tBd6+Iz9NWVaCFwCZv0HpvlvY+59nl37W/pqkcZhu05VreB9bzRV/e+PQ0oSgU0PLQNbl8fRutKgDBAt/G3uh1BhiMzYL4P3iyb7ixVIOjoKaF4Md5ZE4lI5UvIwuIruxED7qQ==";
    };
    "helios" = {
      ssh-ed25519 = "AAAAC3NzaC1lZDI1NTE5AAAAIFBeOiRDTb752+OByHhNQWcEq2htfPwhwnb2jasF7CMr";
      ssh-rsa = "AAAAB3NzaC1yc2EAAAADAQABAAACAQCwxk8gNwWP0Nv7z+ZNXiiwSbTSNsxC3+yj9TkFQb89qkITj/MaWh6sFfDDMAK6bCqwMb+kdv3LaxIPYBG8Pql8mMxP8Fm7zWrbBp7LRjPHQMGWiL9R0l+GVoEmvgTzuAw9GXOfuItuMGIjvPmirdM3w9tYHWzzDWrTBxmX82syQ5ZHvAkGk5yYhc0/u4haFUOFKQIMrxGPwl5aShebUkHHbcPQxnujBNQh822s/36Dnk5RW/a50yDh+mkACfqWSs47RjjbvnCKkODjGKaxRIqJIV98MldRmOQkNgWwu/L9u/McKVNnyGrZuWTTRkoKlEkqdjnw2nO2EYTqH3KfcV5tdJ/+6JDR0GJBXB6c9Mw2No+vh3EBaDdR1hgvhz+5+1kGToR1sqi13gQPA8dwBhVBwLPWqr2zhLRdbucKTHY/UcbxjH7wErSIMoFuL9rG+E1sAJW5rEyKCh0za+h1rMZflKMlaVS/N73OT9tP3cZfBMC/mA+CxY8MNaYzalxFiX3t31p8b3jxUXfwQ1GAMmkRJingMWRik9XVk25ONMu/KMouDCR8R+BrQdVwJer0dYJOd96nzwFbSHL8Rx5Zu1hwRf56wnJMyO05+4qbzFp24+D39/EtsUIFnKHAU5LQak+ySDdo4LzEX4CxSf21zV/IOJ2gSTmzgfdEq6um9WbDHQ==";
    };
    "skullkid" = {
      ssh-ed25519 = "AAAAC3NzaC1lZDI1NTE5AAAAIMiNHW0UczAz+qpv58uCBR0Jzux1rJd36wOktS0t9S8r";
      ssh-rsa = "AAAAB3NzaC1yc2EAAAADAQABAAACAQDn+xUjPDvI7cXs5p9KqpeFFTrp259moz/N1oOt8EnN9MUzp0K/tenryf8knwyT2o6Wbe8e5O/MwUzO3lnNx4yhN1RZgKxIrYa7K+HGX401CJmz12vK5c8ID2IYp6mfpomZPrX9/tQ7VpvKdvbzurx9/OH6knv1oyF+Vqdqqcg2I0dTh3c3TpxbUhVHDev+QP31sT7wl06WhgtqUJx2kQF2tPsfhpalTEi8M7bUGqkSIQbEbKL2oRrSE/9Qn2O4Nfpu69YxyGHrJkjkGwXVVwdZ14m2Uz0PRFzYMYMoYEAL7pq/HxJ7pI38Kat9lLcfjTcsdtV89IsPedhWgChKGEIJKxXpDTUlgUzMfMfUPRrEFC48gIElGdnL1nMCrPsyzsBbMZbLvN57YlWsxZ237s6rb12GReM3kixPDSs1JNtTK/T+lrw7Z/04vvEmpismrULh33p1yK5+uKugeqbG5qA3UfvHEVIKsBpLQWnc5lPovTwcWOiT4v0e0Z9PAd7sYhEkrFgusloGaCHl9dfNgmqOr8+BzMxNLA9ZJXkOs6ptjh8pAoXh1smKpaB3IRfZuBsEyS2AR/rQTrLxnGpTJa7gqR8vacTGmsOMOjs7TYW+fFOkacVjCPETcM9NXNnSTGITPl7CU85rGyPUIsxwBFg/G7Ub+U3VLVWT9+T2v4XqMw==";
    };
  };
  qualifyHosts = hosts: domain: lib.mapAttrs' (name: value: lib.nameValuePair "${name}.${domain}" value) hosts;
  allKnownHosts = knownHosts // tailscaleKnownHosts // (qualifyHosts tailscaleKnownHosts "neko-danio.ts.net");

  forEachKnownHostsEntry = fn: hosts:
    lib.flatten (lib.mapAttrsToList (
        host: keys: lib.mapAttrsToList (type: key: fn host type key) keys
      )
      hosts);

  mkNixosKnownHostAttrs = host: type: key: {
    "${host}/${type}" = {
      hostNames = lib.singleton host;
      publicKey = lib.concatStringsSep " " [type key];
    };
  };
  mkKnownHostsFileEntry = host: type: key: "${host} ${type} ${key}";
in {
  nixos.knownHosts =
    lib.mergeAttrsList
    (forEachKnownHostsEntry mkNixosKnownHostAttrs allKnownHosts);

  mkKnownHostsFile = {extraKnownHosts ? {}}:
    lib.concatStringsSep "\n"
    (forEachKnownHostsEntry mkKnownHostsFileEntry (allKnownHosts // extraKnownHosts));
}
