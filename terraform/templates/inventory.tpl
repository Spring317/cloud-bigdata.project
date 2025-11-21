[master]
master ansible_host=${master_ip} private_ip=${master_private_ip} ansible_user=ubuntu

[workers]
%{ for idx, worker in workers ~}
worker-${idx + 1} ansible_host=${worker.network_interface[0].access_config[0].nat_ip} private_ip=${worker.network_interface[0].network_ip} ansible_user=ubuntu
%{ endfor ~}

[edge]
edge ansible_host=${edge_nodes.network_interface[0].access_config[0].nat_ip} private_ip=${edge_nodes.network_interface[0].network_ip} ansible_user=ubuntu

[spark_cluster:children]
master
workers
edge

[all:vars]
ansible_ssh_private_key_file=~/.ssh/id_rsa
ansible_ssh_common_args='-o StrictHostKeyChecking=no'