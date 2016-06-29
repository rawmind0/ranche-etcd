#!/usr/bin/env bash

SERVICE_TMPL=${SERVICE_TMPL:-"/opt/tools/confd/etc/templates/etcd-source.tmpl"}

cat << EOF > ${SERVICE_TMPL}
#!/usr/bin/env bash

my_ip={{getv "/container/primary_ip"}}
my_name={{getv "/container/name"}}
my_service={{getv "/container/service_name"}}
my_stack={{getv "/container/stack_name"}}
my_status={{getv "/container/health_state"}}
my_endpoint='http://{{getv "/container/service_name"}}:2379'
my_info=\$(etcdctl --endpoints=\$my_endpoint member list | grep -w \$my_ip | grep -v grep)
rc=\$(echo \$?)
my_id=\$(echo \$my_info | cut -d":" -f1)
cluster_healthy=\$(curl -sL \$my_endpoint/health | cut -d"\"" -f4)

function log {
        echo `date` \$ME - $@
}

function addMember {
    log "[ Adding $my_name node to cluster... ]"
    etcdctl --endpoints=\$my_endpoint member add \$my_name http://\$my_ip:2380
}

function removeMember {
    log "[ Removing $my_name node to cluster... ]"
    etcdctl --endpoints=\$my_endpoint member remove \$my_id
}

export ETCD_ADVERTISE_CLIENT_URLS=\${ETCD_ADVERTISE_CLIENT_URLS:-"http://\$my_ip:2379"}
export ETCD_DATA_DIR=\${ETCD_DATA_DIR:-\${SERVICE_HOME}"/data"}
export ETCD_INITIAL_ADVERTISE_PEER_URLS=\${ETCD_INITIAL_ADVERTISE_PEER_URLS:-"http://\$my_ip:2380"}
export ETCD_INITIAL_CLUSTER=\${ETCD_INITIAL_CLUSTER:-'{{range \$i, \$containerName := ls "/service/containers"}}{{if \$i}},{{end}}{{getv (printf "/service/containers/%s/name" \$containerName)}}=http://{{getv (printf "/service/containers/%s/primary_ip" \$containerName)}}:2380{{end}}'}

if [ "x\$cluster_healthy" == "xtrue" ] || [ "x\$cluster_healthy" == "xfalse" ];then
        ETCD_INITIAL_CLUSTER_STATE="existing"
        if [ \$rc -eq 1 ]; then
                addMember
        fi
fi

export ETCD_INITIAL_CLUSTER_STATE=\${ETCD_INITIAL_CLUSTER_STATE:-"new"}
export ETCD_INITIAL_CLUSTER_TOKEN=\${ETCD_INITIAL_CLUSTER_TOKEN:-"\$my_service-\$my_stack"}
export ETCD_NAME=\${ETCD_NAME:-"\$my_name"}
export ETCD_LISTEN_PEER_URLS=\${ETCD_LISTEN_PEER_URLS:-"http://\$my_ip:2380"}
export ETCD_LISTEN_CLIENT_URLS=\${ETCD_LISTEN_CLIENT_URLS:-"http://\$my_ip:2379,http://127.0.0.1:2379"}
EOF



