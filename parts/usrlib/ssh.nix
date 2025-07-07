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
    "linode-arch.neko-danio.ts.net" = {
      ecdsa-sha2-nistp256 = "AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBDKudRpK8c+opPGokE2f5Z7gd2yWTHRrA6p3/YayieSRTDOnmb4aR1Pmbz967KBeo+KYm+4R/d59p4mABKPztNU=";
      ssh-ed25519 = "AAAAC3NzaC1lZDI1NTE5AAAAIE/xP/0LQP88FKB3cQKuMvHCj53UiAMnV3rZFQiMsLkV";
      ssh-rsa = "AAAAB3NzaC1yc2EAAAADAQABAAABgQDR76lteEphRkj6ifIQbd8T7XjzsALnIt51kptcR40e6TcHzn2/0ptqRbadad5sDKQ8lZJmUX+Sz6FM1o7M8zKnoxs7HkjnjvK0Tj/19O1PJ88eygKhlFjFeLyV17Ib+zKD3IYcQcalv701FU2CFV+WV5o/RUIh1SQX69g4H+iiBXinT3NNLTNnCq3+2epU0vxbrsLNUGfvjfRGB2GVE4Tj2CzDrwu+wz1LaHKeMC60jUfdrjbzpTg4EJixm42QsU2RNTc4w+hNHcuRtgd8WG/FryQEW1P+v7hUxbxwhorevYPmQevl59UTW5WtvQvkTUl2SaezSpOpk0vTktJhVsiQOcCnp2I1dD7kthucn2ar5VbAIcD+q3bJJAUXyrJKFSj4t5G7jNcdTJjVcD/rCoY5oDkIHpIyFoVlueKkrczYW/LV4xXj9Psfdg0oEstjEupVsMkzqSBXmWJ2JkAJHlHwSc87ofPjuVSUqdr+iA1d5KNmE+JqdL0JqHDVIbdhlqU=";
    };
    "heimdall.neko-danio.ts.net" = {
      ssh-ed25519 = "AAAAC3NzaC1lZDI1NTE5AAAAIOBffqWJu60tEBRH9t7aA/Za9BHPghKRt+Ihaie60YTf";
      ssh-rsa = "AAAAB3NzaC1yc2EAAAADAQABAAACAQDmrInYDqQ1w3PCVTmavg95gAo2h73ybn1L73wwr7ijWFHI9K95M33OeQzTN84Mgt6v5QzejmgTAnyqTYGmxqzHUEJ6K5MXKxz6BawDvZy40n7Y3D6NnQTllxvPRrBurD0FVULqORB5Ls/L4eExQbAKZuHUm+PNLkc9t+uxMQFPnGO5mu+fAJLajCnXRtw/YAOSFQ66PaZNVAQMaXUTK8WGwgbanfpYbiyeUhnQTQe+ulrfYikXgS7X2M/l7I08JcMhqzSWzh6iTtxZvR8DRdCEd8TJddZrAlQIrjurhk3LccDjSiwi6I35AQQjl+MNSJKH/hes6ECL799NEuT556ZGTuCTmHAKTa2J9EWxAefspUDnIlSBv4O826f+1yEo6erw6tEWBxG1XR7QSVGt+K9W82GpoFmB3iMq51Ympw6TIqM+gM/YtIXVLY3LOjH2cGAw7CDP5k9FeBRqVO4+YdLTXm6/s1LeRJMnGUkuerQdo3g96WeYTKt1TICFCDUqrl14gxfIX8+71Sbi5RrNg2tX00yyN+XTz0iYUmvxj3z/CRKq/NbeOBT2P0GNE6VVJ1oQuZct4q4BhhuWQUMegpS7X46ZhKGa3E37SekiTLKOtxE9dD+6XP8eB6EaZksC+zDQVHDgROGZUi8gR0eDjwQTEOa6OhIr0Wa6mi3l3AhHDQ==";
    };
    "linode.neko-danio.ts.net" = {
      ssh-ed25519 = "AAAAC3NzaC1lZDI1NTE5AAAAIMVouzrCM9iNkhf3E7yOGPggY6xeBmjfKnwymsSBQ/Af";
      ssh-rsa = "AAAAB3NzaC1yc2EAAAADAQABAAACAQC7QcBkDyoEq57lbAmigUjjfcmbDImHxRZC6h6nEl2ddgNBfDn/PnnU2s1VuzyZggWQPIc+FyHBcodBGP0sy2w8lv9ikqsivhWG6EO+Bj1qefxgU8sxIZ1imFP2nIwUDLUv5Gv5UEexOVQ/DxPgHLRvAqTUiNeu4/aaViG/8AHmPrIxS+zxeYjwg3+v4b0Yf87dUukfkxSLAsxL1vlMSTaNpBqLGNUI4FCLA1Ne95bXlBvY3KM8vDr0SilU8eBkJshn5tgbPnjGgbO3VPAxYp7f76dMJJcsQ5C3pWDAuPQZwpRKnT/ghU7NOXK2Mfo14VMS+FDKfVOkcpvBSRvgE9N+2RHRDdTvWJDSOi5p9Pb/khwlWU5fBz5GXwieFaAyPc2eAw+fA9gZlq6szxTy63yljMNem/koziIgeYnSV9Jqw9E6tdkWzsfSncNI/NewkmyDMFcTQ6dw+dca1OAne0GSiQU3OyG4sjDWvPZUF1L+4ymM3pr7beTsJP5e98LoJWpdzCmr/eyeSBxQwA3cMOGNWfBxMVh25FhqBktJ3NgwGAAGGQRNHqdMSZuFe7sC6AFKMSi3SB4zMXvDhl4vxKTNFNSo0/L7QdoloHlmq/Iz3SmzC7Aq9n/JDpFF6EzRO518YJ6AiXzcXw/CaizZratlTiQVrZWwgnPK/mic1XF2aQ==";
    };
    "nyx.neko-danio.ts.net" = {
      ssh-ed25519 = "AAAAC3NzaC1lZDI1NTE5AAAAIJmofQEhKZ7TOhqDMBwBr/p7ffOq2caH43ea1w/AsKoS";
      ssh-rsa = "AAAAB3NzaC1yc2EAAAADAQABAAACAQCN42MTL5EUXBc8OEKp3ddH4D7jQe1RYo4l2MFtfsgg3J1KNndRo4ym/VVY5HZKJ3Fk5TqPFbwOP4v8ZcmFK57SuzyyMfzh/2kD8XTGnPJSkwTcTsr9rRuxXus8rQ0Srn2gLi0ai64c5jWcPTne+ZpD/0dA/Xkp+g48Ftvd5DNFGTqY5rAQ5cnRIebt/XNfiCwQ1Y57/q5pwI1A1pCl5X5uk938INv210VdQe2aHa8vL3hbtDkCehC92ST24YDeYKE74BtPN9mAAfXc5vgfoCHaEUnRZNz+ZoGJ+Gvs4V3U9DacrrLKHjpMwoNc/U6d2lvP5q8Xej6pPpf9EbGXMqxjQfgPvYyQ3nxco8prZAYVUOmxUH1rNBCUB4PoUeXW1KvaxZ8Jy+7wED/6WmobggY+CyeWM6VmLIt/WqMBIFolnGOay2dNFN4SSku1lOj5iJzOUIR7JvRzsW4p5yvlIoIgrmKRLiFwZ0BEK9aQhvu+anhjdiXv+DLAhOzV0Cfr0rsY0jQyF2bbB0lBfyZkwDaGkiYrFo/Zi831DTu9tBd6+Iz9NWVaCFwCZv0HpvlvY+59nl37W/pqkcZhu05VreB9bzRV/e+PQ0oSgU0PLQNbl8fRutKgDBAt/G3uh1BhiMzYL4P3iyb7ixVIOjoKaF4Md5ZE4lI5UvIwuIruxED7qQ==";
    };
    "helios.neko-danio.ts.net" = {
      ssh-ed25519 = "AAAAC3NzaC1lZDI1NTE5AAAAIFBeOiRDTb752+OByHhNQWcEq2htfPwhwnb2jasF7CMr";
      ssh-rsa = "AAAAB3NzaC1yc2EAAAADAQABAAACAQCwxk8gNwWP0Nv7z+ZNXiiwSbTSNsxC3+yj9TkFQb89qkITj/MaWh6sFfDDMAK6bCqwMb+kdv3LaxIPYBG8Pql8mMxP8Fm7zWrbBp7LRjPHQMGWiL9R0l+GVoEmvgTzuAw9GXOfuItuMGIjvPmirdM3w9tYHWzzDWrTBxmX82syQ5ZHvAkGk5yYhc0/u4haFUOFKQIMrxGPwl5aShebUkHHbcPQxnujBNQh822s/36Dnk5RW/a50yDh+mkACfqWSs47RjjbvnCKkODjGKaxRIqJIV98MldRmOQkNgWwu/L9u/McKVNnyGrZuWTTRkoKlEkqdjnw2nO2EYTqH3KfcV5tdJ/+6JDR0GJBXB6c9Mw2No+vh3EBaDdR1hgvhz+5+1kGToR1sqi13gQPA8dwBhVBwLPWqr2zhLRdbucKTHY/UcbxjH7wErSIMoFuL9rG+E1sAJW5rEyKCh0za+h1rMZflKMlaVS/N73OT9tP3cZfBMC/mA+CxY8MNaYzalxFiX3t31p8b3jxUXfwQ1GAMmkRJingMWRik9XVk25ONMu/KMouDCR8R+BrQdVwJer0dYJOd96nzwFbSHL8Rx5Zu1hwRf56wnJMyO05+4qbzFp24+D39/EtsUIFnKHAU5LQak+ySDdo4LzEX4CxSf21zV/IOJ2gSTmzgfdEq6um9WbDHQ==";
    };
    "selene.neko-danio.ts.net" = {
      ssh-ed25519 = "AAAAC3NzaC1lZDI1NTE5AAAAIOsTlULQNZe35e1q4ztyqe73WRgBAhdIWwirhTJMMY2s";
      ssh-rsa = "AAAAB3NzaC1yc2EAAAADAQABAAACAQCiHrD2gS7AGUoxTt5AW0Z85LXwcbRpekJTxj0wM6uhCbAJmyRgHFA2gpGoPURMwGF2H83lAmG/ZtcfDH/DSycd1r6YSdoLZGhG96PWg3jHjMyPIGQKRIFd3pgPVnPYeABwJR4/11Clx8e6FOJj9mmZdyW+UV+MpgUeQTaEpodjK8+4TDjPheaWlqvotEFYFqaWxJSSlh/7Jw9WnpHyXdeQ4ZrFqKsYzCKaDt5n++p6qc38Mz6rp2w4FOARnsUkUE3gkO/tOAMhqPttmK9yGRnV6I5zLi6tkE4CwYusQ6y9qIkyHIWjfH24L3qVfVK3y2at0MdwXLiVNG9Hh7U8lazjeOeT44MSWj7O/n+HGxZpnXsvt4k6uRw8Ft1KptLxohGPYZMCc3HPtzSrthBtoxX29riq1SqZk5LZB6vwM59L1M8RHuKfNIrkcNUJML+uePwkIMV7xmiriJ/1JYo3T3c6tFdJu2px9rKSpByzVVah8CJ/zu5PB5D8f/y8TvNMHcHCO6OJ4pERFg+OVfYpb3pjJgL8sPdWPTCXlxNE5rSrp9pqQxfskT3mBAAefZGG7HJJVY4Ph65OKSvnSqv3ass2BYEDAcKtS+gkjz/g4DAMBvgdp/5jEAzk9CLKr03Gs3I/8Q+nqSaHbthLLN5TSUbSnPCxb1UwY6r1C85Fk33Kcw==";
    };
  };

  forEachKnownHostsEntry = fn: hosts:
    lib.flatten (lib.mapAttrsToList (
        host: keys: lib.mapAttrsToList (type: key: fn host type key) keys
      )
      hosts);

  genNixosKnownHostAttrs = host: type: key: {
    "${host}/${type}" = {
      hostNames = lib.singleton host;
      publicKey = lib.concatStringsSep " " [type key];
    };
  };
  genKnownHostsFileEntry = host: type: key: "${host} ${type} ${key}";
in {
  nixos.knownHosts =
    lib.mergeAttrsList
    (forEachKnownHostsEntry genNixosKnownHostAttrs knownHosts);

  genKnownHostsFile = {extraKnownHosts ? {}}:
    lib.concatStringsSep "\n"
    (forEachKnownHostsEntry genKnownHostsFileEntry (knownHosts // extraKnownHosts));
}
