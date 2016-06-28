#!/usr/bin/env bash

SERVICE_TMPL=${SERVICE_TMPL:-"/opt/tools/confd/etc/templates/etcd-source.tmpl"}

cat << EOF > ${SERVICE_TMPL}
{{\$my_ip := getv "/container/primary_ip"}}{{\$my_name := getv "/container/name"}}
export ETCD_ADVERTISE_CLIENT_URLS=\${ETCD_ADVERTISE_CLIENT_URLS:-'http://{{\$my_ip}}:2379'}
export ETCD_DATA_DIR=\${ETCD_DATA_DIR:-\${SERVICE_HOME}"/data"}
export ETCD_INITIAL_ADVERTISE_PEER_URLS=\${ETCD_INITIAL_ADVERTISE_PEER_URLS:-'http://{{\$my_ip}}:2380'}
export ETCD_INITIAL_CLUSTER=\${ETCD_INITIAL_CLUSTER:-'{{range \$i, \$containerName := ls "/service/containers"}}{{if \$i}},{{end}}{{getv (printf "/service/containers/%s/name" \$containerName)}}=http://{{getv (printf "/service/containers/%s/primary_ip" \$containerName)}}:2380{{end}}'}
export ETCD_INITIAL_CLUSTER_STATE=\${ETCD_INITIAL_CLUSTER_STATE:-"new"}
export ETCD_INITIAL_CLUSTER_TOKEN=\${ETCD_INITIAL_CLUSTER_TOKEN:-'{{getv "/container/service_name"}}-{{getv "/container/stack_name"}}'}
export ETCD_NAME=\${ETCD_NAME:-'{{\$my_name}}'}
export ETCD_LISTEN_PEER_URLS=\${ETCD_LISTEN_PEER_URLS:-'http://{{\$my_ip}}:2380'}
export ETCD_LISTEN_CLIENT_URLS=\${ETCD_LISTEN_CLIENT_URLS:-'http://{{\$my_ip}}:2379,http://127.0.0.1}:2379'}
EOF
