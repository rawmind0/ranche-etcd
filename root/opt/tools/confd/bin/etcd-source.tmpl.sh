#!/usr/bin/env bash

cat << EOF > ${SERVICE_VOLUME}/confd/etc/conf.d/etcd-source.toml
[template]
prefix = "/self"
src = "etcd-source.tmpl"
dest = "${SERVICE_HOME}/etc/etcd-source"
owner = "${SERVICE_USER}"
mode = "0644"
keys = [
  "/container",
  "/service",
]
EOF

cat << EOF > ${SERVICE_VOLUME}/confd/etc/templates/etcd-source.tmpl
#!/usr/bin/env bash

my_ip={{getv "/container/primary_ip"}}
my_name={{getv "/container/name"}}
my_service={{getv "/container/service_name"}}
my_stack={{getv "/container/stack_name"}}
my_status={{getv "/container/health_state"}}
my_endpoint='http://{{getv "/container/service_name"}}:2379'
cluster_member_list=\$(etcdctl --endpoints=\$my_endpoint member list)
cluster_member_rc=\$(echo \$?)

if [ \$cluster_member_rc -eq 0 ];then
	my_info=\$(echo \$cluster_member_list | grep -w \$my_ip | grep -v grep)
	my_rc=\$(echo \$?)
	my_id=\$(echo \$my_info | cut -d":" -f1)
	cluster_healthy=\$(curl -sL \$my_endpoint/health | cut -d"\"" -f4)
else
    cluster_healthy="new"
fi

function log {
        echo `date` \$ME - \$@
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
    if [ \$my_rc -eq 1 ]; then
        addMember
    fi
else 
	ETCD_INITIAL_CLUSTER_STATE="new"
fi

export ETCD_INITIAL_CLUSTER_STATE=\${ETCD_INITIAL_CLUSTER_STATE}
export ETCD_INITIAL_CLUSTER_TOKEN=\${ETCD_INITIAL_CLUSTER_TOKEN:-"\$my_service-\$my_stack"}
export ETCD_NAME=\${ETCD_NAME:-"\$my_name"}
export ETCD_LISTEN_PEER_URLS=\${ETCD_LISTEN_PEER_URLS:-"http://\$my_ip:2380"}
export ETCD_LISTEN_CLIENT_URLS=\${ETCD_LISTEN_CLIENT_URLS:-"http://\$my_ip:2379,http://127.0.0.1:2379"}
EOF



