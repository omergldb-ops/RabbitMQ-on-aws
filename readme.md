High-Availability RabbitMQ Cluster on AWS
Built with Terraform & Ubuntu 24.04 LTS
This project demonstrates a production-grade, self-healing RabbitMQ cluster architecture. It utilizes Infrastructure as Code (IaC) to deploy a distributed system across multiple Availability Zones, featuring automated peer discovery and load balancing.

🏗 Architecture Overview
The infrastructure is designed for high availability and security, following AWS best practices:

VPC & Networking: A custom VPC with Public and Private subnets. RabbitMQ nodes are isolated in Private Subnets to prevent direct internet exposure.

Load Balancing: An Application Load Balancer (ALB) sits in the public subnets, acting as the entry point for the Management UI.

Auto Scaling: A Launch Template and Auto Scaling Group (ASG) ensure that 3 nodes are always running. If a node fails, the ASG automatically replaces it.

Peer Discovery: Utilizes the rabbitmq_peer_discovery_aws plugin. Nodes automatically find each other by querying the AWS API for instances belonging to the same ASG—no manual IP hardcoding required.

Security Groups: Strictly defined ingress/egress rules for AMQP (5672), Management (15672), and Erlang Distribution (25672/4369).

🛠 Tech Stack
Infrastructure: Terraform

Cloud Provider: AWS (EC2, VPC, IAM, ALB, ASG)

OS: Ubuntu 24.04 LTS (Noble Numbat)

Message Broker: RabbitMQ 3.12+

Language/Runtime: Erlang/OTP

🚀 Key Features Implemented
1. Automated Cluster Formation
Instead of manual clustering, I implemented AWS Peer Discovery. The nodes use a shared Erlang Cookie and an IAM Role with ec2:DescribeInstances permissions to dynamically form a cluster upon boot.

2. Infrastructure as Code (IaC)
The project is fully modularized:

vpc: Networking stack.

security: IAM roles and Security Groups.

rabbitmq: Launch templates and Auto Scaling.

3. Advanced UserData Scripting
The user_data.sh script handles:

Repository injection for RabbitMQ/Erlang on the latest Ubuntu 24.04.

Automated plugin activation.

Custom configuration file generation (rabbitmq.conf).

Administrative user creation for remote management access.

🔧 Deployment & Troubleshooting
During development, I encountered and resolved several critical "real-world" issues:

ALB 502 Bad Gateway: Diagnosed as a delay in cloud-init execution; resolved by optimizing the health check grace period and verifying service startup.

Package Management: Navigated repository differences between Amazon Linux 2023 and Ubuntu 24.04 to ensure reliable software installation via apt and dnf.

Remote Access: Overcame RabbitMQ’s default "Loopback User" restriction by programmatically creating an admin user via rabbitmqctl.

🚦 How to Use
Initialize Terraform: terraform init

Deploy Infrastructure: terraform apply -var-file="root.tfvars"

Access the UI: Get the alb_dns_name from the outputs and log in with the admin credentials defined in the UserData.