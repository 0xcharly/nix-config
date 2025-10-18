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
album           IN CNAME heimdall
atuin           IN CNAME heimdall
beans           IN CNAME heimdall
files           IN CNAME heimdall
gatus           IN CNAME heimdall
graphs          IN CNAME heimdall
healthchecks    IN CNAME heimdall
jellyfin        IN CNAME heimdall
news            IN CNAME heimdall
prometheus      IN CNAME heimdall
push            IN CNAME heimdall
reads           IN CNAME heimdall
shared.album    IN CNAME heimdall
status          IN CNAME heimdall
tasks           IN CNAME heimdall
vault           IN CNAME heimdall

bowmore         IN CNAME bowmore.@tailnetName@.
dalmore         IN CNAME dalmore.@tailnetName@.
fwk             IN CNAME fwk.@tailnetName@.
helios          IN CNAME helios.@tailnetName@.
linode          IN CNAME linode.@tailnetName@.
linode-fr       IN CNAME linode-fr.@tailnetName@.
linode-jp       IN CNAME linode-jp.@tailnetName@.
nyx             IN CNAME nyx.@tailnetName@.
rip             IN CNAME rip.@tailnetName@.
skl             IN CNAME skl.@tailnetName@.
