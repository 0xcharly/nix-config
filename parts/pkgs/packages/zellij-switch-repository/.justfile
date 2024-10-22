import '.justfile.incl'

set shell := ['fish', '-c']

[doc('List all available commands')]
[private]
default:
    @just --list

[doc('Start a Zellij session with the devel layout')]
dev:
    zellij --layout .config/dev.kdl

[doc('Start a Zellij session with the devel layout')]
launch:
    zellij --layout share/launch-sessionizer.kdl

build *flavor="":
  cargo build --target=wasm32-wasip1 {{ flavor }}
