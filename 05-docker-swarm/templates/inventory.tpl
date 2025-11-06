[swarm_managers]
%{ for idx, ip_list in manager_ips ~}
docker-manager-${idx + 1} ansible_host=${ip_list[0]} ansible_user=ubuntu
%{ endfor ~}

[swarm_workers]
%{ for idx, ip_list in worker_ips ~}
docker-worker-${idx + 1} ansible_host=${ip_list[0]} ansible_user=ubuntu
%{ endfor ~}

[swarm:children]
swarm_managers
swarm_workers
