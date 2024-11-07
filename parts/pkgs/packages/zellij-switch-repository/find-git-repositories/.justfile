set shell := ['fish', '-c']

[doc('List all available commands')]
[private]
default:
    @just --list

[doc("Format all files in this directory and its subdirectories.")]
fmt:
    @just --justfile ../.justfile --working-directory . fmt

[doc('Start a Zellij session with the devel layout')]
dev:
    zellij --layout .config/dev.kdl

build *flavor="":
  cargo build {{ flavor }}
