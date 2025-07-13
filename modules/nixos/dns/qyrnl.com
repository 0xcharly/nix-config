$ORIGIN qyrnl.com.
$TTL    3600

@       IN SOA  ns.qyrnl.com. hostmaster.qyrnl.com. 2025070100 86400 10800 3600000 3600
@   300 IN NS   ns1.qyrnl.com.
@   300 IN NS   ns2.qyrnl.com.
ns1 300 IN A    @tailscaleIPv4@
ns1 300 IN AAAA @tailscaleIPv6@
ns2 300 IN A    @tailscaleIPv4@
ns2 300 IN AAAA @tailscaleIPv6@

heimdall        IN CNAME heimdall.@tailnetName@.
atuin           IN CNAME heimdall
beans           IN CNAME heimdall
jellyfin        IN CNAME heimdall
status          IN CNAME heimdall
vault           IN CNAME heimdall

helios          IN CNAME helios.@tailnetName@.
images          IN CNAME helios

nyx             IN CNAME nyx.@tailnetName@.
selene          IN CNAME selene.@tailnetName@.
linode          IN CNAME linode.@tailnetName@.
