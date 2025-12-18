#!/bin/bash
yum update -y
amazon-linux-extras install docker -y
systemctl enable --now docker

# wait until docker is active (max ~2.5 minutes)
for i in {1..30}; do
  if systemctl is-active --quiet docker; then
    break
  fi
  echo "waiting for docker ($i)"
  sleep 5
done

# ensure images are pulled before running containers
docker pull rabbitmq:3-management || true
docker pull hashicorp/http-echo || true

# run rabbitmq with restart policy so it survives reboots
docker run -d --restart unless-stopped \
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
# pull then run with restart policy
docker run -d --restart unless-stopped --name http-health -p 8080:8080 hashicorp/http-echo -text="OK" -listen=":8080"

# give containers time to start
sleep 20