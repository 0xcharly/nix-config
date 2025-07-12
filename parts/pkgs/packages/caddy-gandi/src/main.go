// Forked from: https://github.com/caddyserver/caddy/cmd/caddy/main.go
//
//  1. Add modules below as necessary.
//  2. Run `go mod init caddy`, `go mod tidy`.
//  3. Run `go build` to verify that the binary builds.

package main

import (
	caddycmd "github.com/caddyserver/caddy/v2/cmd"

	_ "github.com/caddyserver/caddy/v2/caddyconfig/caddyfile"
	_ "github.com/caddyserver/caddy/v2/modules/standard"
	// Add Caddy modules below.
	_ "github.com/caddy-dns/gandi"
)

func main() {
	caddycmd.Main()
}
