#!/bin/bash
set -e

echo "Running Ansible playbook..."
ansible-playbook -i inventory.ini setup-user.yml
