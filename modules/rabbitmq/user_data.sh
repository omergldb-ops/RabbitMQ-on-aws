#!/bin/bash
# 1. Update and Upgrade
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get upgrade -y

# 2. Install Dependencies and RabbitMQ
# Ubuntu 24.04 includes RabbitMQ 3.12+ in its default repos
apt-get install -y erlang-nox rabbitmq-server socat

# 3. Set the Erlang Cookie (Required for Clustering)
# All nodes must share this exact secret string
COOKIE_FILE="/var/lib/rabbitmq/.erlang.cookie"
systemctl stop rabbitmq-server
echo "UBUNTU_CLUSTER_COOKIE_2025" > $COOKIE_FILE
chown rabbitmq:rabbitmq $COOKIE_FILE
chmod 400 $COOKIE_FILE

# 4. Enable and Start the service
systemctl enable rabbitmq-server
systemctl start rabbitmq-server

# 5. Enable Plugins
# 'rabbitmq_peer_discovery_aws' is built-in to modern RabbitMQ versions
rabbitmq-plugins enable rabbitmq_management
rabbitmq-plugins enable rabbitmq_peer_discovery_aws

# 6. Configure AWS Peer Discovery
mkdir -p /etc/rabbitmq
cat <<EOF > /etc/rabbitmq/rabbitmq.conf
# AWS Clustering Settings
cluster_formation.peer_discovery_backend = aws
cluster_formation.aws.region = us-east-1
cluster_formation.aws.use_autoscaling_group = true

# UI Management Port
management.tcp.port = 15672
EOF

chown rabbitmq:rabbitmq /etc/rabbitmq/rabbitmq.conf

# 7. Create Admin User (Since 'guest' is restricted to localhost)
rabbitmqctl add_user admin YourSecurePassword123
rabbitmqctl set_user_tags admin administrator
rabbitmqctl set_permissions -p / admin ".*" ".*" ".*"

# 8. Final Restart
systemctl restart rabbitmq-server