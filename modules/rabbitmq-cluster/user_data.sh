#!/bin/bash
yum update -y
amazon-linux-extras install docker -y
systemctl enable --now docker

docker run -d \
  --name rabbitmq \
  -p 15672:15672 \
  -p 5672:5672 \
  -p 4369:4369 \
  -p 25672:25672 \
  -e RABBITMQ_DEFAULT_USER=admin \
  -e RABBITMQ_DEFAULT_PASS=DemoRabbit123! \
  -e RABBITMQ_SERVER_ADDITIONAL_ERLANG_ARGS="-kernel inet_dist_use_interface {0,0,0,0}" \
  rabbitmq:3-management

# small unauthenticated HTTP endpoint for ALB health checks on port 8080
# using hashicorp/http-echo so / returns 200 OK
docker run -d --name http-health -p 8080:8080 hashicorp/http-echo -text="OK" -listen=":8080"

sleep 20