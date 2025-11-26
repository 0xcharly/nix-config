$ORIGIN qyrnl.com.
$TTL    3600

@       IN SOA  ns.qyrnl.com. hostmaster.qyrnl.com. 2025070100 86400 10800 3600000 3600
@   300 IN NS   ns1.qyrnl.com.
@   300 IN NS   ns2.qyrnl.com.
@   300 IN NS   ns3.qyrnl.com.
ns1 300 IN A    100.76.97.8
ns1 300 IN AAAA fd7a:115c:a1e0::b736:6108
ns2 300 IN A    100.83.95.114
ns2 300 IN AAAA fd7a:115c:a1e0::e736:5f72
ns3 300 IN A    100.85.79.53
ns3 300 IN AAAA fd7a:115c:a1e0::4036:4f35

heimdall        IN CNAME heimdall.@tailnetName@.
bowmore         IN CNAME bowmore.@tailnetName@.
dalmore         IN CNAME dalmore.@tailnetName@.
fk-13           IN CNAME fk-13.@tailnetName@.
linode-fr       IN CNAME linode-fr.@tailnetName@.
linode-jp       IN CNAME linode-jp.@tailnetName@.
nyx             IN CNAME nyx.@tailnetName@.
rip             IN CNAME rip.@tailnetName@.
skl             IN CNAME skl.@tailnetName@.

album           IN CNAME linode-jp
atuin           IN CNAME linode-jp
beans           IN CNAME linode-jp
files           IN CNAME linode-jp
gatus           IN CNAME linode-jp
git             IN CNAME linode-jp
graphs          IN CNAME linode-jp
healthchecks    IN CNAME linode-jp
jellyfin        IN CNAME linode-jp
news            IN CNAME linode-jp
prometheus      IN CNAME linode-jp
push            IN CNAME linode-jp
reads           IN CNAME linode-jp
github          IN CNAME linode-jp
shared.album    IN CNAME linode-jp
status          IN CNAME linode-jp
tasks           IN CNAME linode-jp
vault           IN CNAME linode-jp
