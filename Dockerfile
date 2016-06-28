FROM rawmind/rancher-tools:0.3.4-2
MAINTAINER Raul Sanchez <rawmind@gmail.com>

#Set environment
ENV SERVICE_NAME=etcd \
    SERVICE_USER=etcd \
    SERVICE_UID=10005 \
    SERVICE_GROUP=etcd \
    SERVICE_GID=10005 

# Add service files
ADD root /
