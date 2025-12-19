#!/bin/bash
# 1. Update the system packages
dnf update -y

# 2. Add RabbitMQ and Erlang Repositories (Official Cloudsmith mirrors)
curl -s https://packagecloud.io/install/repositories/rabbitmq/erlang/script.rpm.sh | bash
curl -s https://packagecloud.io/install/repositories/rabbitmq/rabbitmq-server/script.rpm.sh | bash

# 3. Install Erlang and RabbitMQ Server
dnf install -y erlang rabbitmq-server

# 4. Set the Erlang Cookie (Crucial for nodes to talk to each other)
# All nodes in the cluster MUST have the exact same cookie string.
COOKIE_FILE="/var/lib/rabbitmq/.erlang.cookie"
echo "RABBITMQ_CLUSTER_COOKIE_2025" > $COOKIE_FILE
chown rabbitmq:rabbitmq $COOKIE_FILE
chmod 400 $COOKIE_FILE

# 5. Enable and Start the RabbitMQ Service
systemctl enable rabbitmq-server
systemctl start rabbitmq-server

# 6. Enable Management UI and AWS Peer Discovery Plugin
# This plugin allows nodes to find each other using AWS Auto Scaling tags
rabbitmq-plugins enable rabbitmq_management
rabbitmq-plugins enable rabbitmq_peer_discovery_aws

# 7. Configure RabbitMQ for AWS Clustering
mkdir -p /etc/rabbitmq
cat <<EOF > /etc/rabbitmq/rabbitmq.conf
# Use AWS Peer Discovery
cluster_formation.peer_discovery_backend = aws
cluster_formation.aws.region = us-east-1
cluster_formation.aws.use_autoscaling_group = true

# Port for the Management UI
management.tcp.port = 15672
EOF

# Ensure the rabbitmq user owns the config file
chown rabbitmq:rabbitmq /etc/rabbitmq/rabbitmq.conf

# 8. Create an Admin User for the Web UI
# Default 'guest' user is blocked from remote access (ALB access)
rabbitmqctl add_user admin YourPassword123
rabbitmqctl set_user_tags admin administrator
rabbitmqctl set_permissions -p / admin ".*" ".*" ".*"

# 9. Restart to apply all configurations
systemctl restart rabbitmq-server