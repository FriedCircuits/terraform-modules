#!/bin/bash
set -e

eval "$(jq -r '@sh "k8s_host=\(.hostname) ssh_user=\(.ssh_user)"')"

out=$(ssh -q ${ssh_user}@${k8s_host} <<'EOF'
kubeadm token create --print-join-command
EOF
)

join_command="${out##*$'\n'}"
join_command="$(echo "$join_command"|tr -d '\n')"

join_command=($join_command)


echo $(jq -n --arg host "${join_command[2]}" --arg token "${join_command[4]}" --arg cacerthash "${join_command[6]}" '{"host":$host,"token":$token,"cacerthash":$cacerthash}')
