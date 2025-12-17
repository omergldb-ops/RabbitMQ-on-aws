#!/bin/bash
yum update -y
amazon-linux-extras install docker -y
systemctl enable --now docker

RABBITMQ_PASS="DemoRabbit123!"

docker run -d \
  --name rabbitmq \
  --hostname rabbitmq-$(curl -s http://169.254.169.254/latest/meta-data/instance-id) \
  -p ${admin_port}:15672 \
  -p ${amqp_port}:5672 \
  -e RABBITMQ_DEFAULT_USER=admin \
  -e RABBITMQ_DEFAULT_PASS="$RABBITMQ_PASS" \
  rabbitmq:3-management