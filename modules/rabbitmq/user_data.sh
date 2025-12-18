#!/bin/bash
# 1. Install RabbitMQ & Erlang
yum update -y
yum install -y rabbitmq-server
systemctl enable rabbitmq-server
systemctl start rabbitmq-server

# 2. Enable Management UI and AWS Peer Discovery Plugin
rabbitmq-plugins enable rabbitmq_management
rabbitmq-plugins enable rabbitmq_peer_discovery_aws

# 3. Configure RabbitMQ to find other nodes using AWS Tags
cat <<EOF > /etc/rabbitmq/rabbitmq.conf
# Use AWS Peer Discovery
cluster_formation.peer_discovery_backend = aws
cluster_formation.aws.region = us-east-1
# This tells RabbitMQ to look for other nodes in the same ASG
cluster_formation.aws.use_autoscaling_group = true

# Standard Management Port
management.tcp.port = 15672
EOF

# 4. Restart to apply configuration
systemctl restart rabbitmq-server