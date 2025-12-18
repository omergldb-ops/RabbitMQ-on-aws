#!/bin/bash
# 1. Update system
yum update -y

# 2. Install Erlang (Dependency) and RabbitMQ from Amazon Linux Extras
# This works for Amazon Linux 2. 
amazon-linux-extras install epel -y
amazon-linux-extras install rabbitmq-server -y

# 3. Start and Enable the service
systemctl enable rabbitmq-server
systemctl start rabbitmq-server

# 4. Enable Management UI and Peer Discovery
rabbitmq-plugins enable rabbitmq_management
rabbitmq-plugins enable rabbitmq_peer_discovery_aws

# 5. Configuration for Clustering
mkdir -p /etc/rabbitmq
cat <<EOF > /etc/rabbitmq/rabbitmq.conf
cluster_formation.peer_discovery_backend = aws
cluster_formation.aws.region = us-east-1
cluster_formation.aws.use_autoscaling_group = true
management.tcp.port = 15672
EOF

# 6. Restart to apply
systemctl restart rabbitmq-server