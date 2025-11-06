[k3s_masters]
%{ for idx, ip_list in master_ips ~}
k3s-master-${idx + 1} ansible_host=${ip_list[1][0]} ansible_user=ubuntu
%{ endfor ~}

[k3s_workers]
%{ for idx, ip_list in worker_ips ~}
k3s-worker-${idx + 1} ansible_host=${ip_list[1][0]} ansible_user=ubuntu
%{ endfor ~}

[k3s:children]
k3s_masters
k3s_workers
