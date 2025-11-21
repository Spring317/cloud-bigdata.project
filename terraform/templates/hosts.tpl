127.0.0.1 localhost
${master_private_ip} master spark-master
%{ for idx, worker in workers ~}
${worker.network_interface[0].network_ip} worker-${idx + 1}
%{ endfor ~}
${edge_nodes.network_interface[0].network_ip} edge

# The following lines are desirable for IPv6 capable hosts
::1 ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
ff02::3 ip6-allhosts
169.254.169.254 metadata.google.internal metadata