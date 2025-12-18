# Fetch latest Amazon Linux 2 AMI
data "aws_ssm_parameter" "amazon_linux_2" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

# Use default VPC
data "aws_vpc" "default" {
  default = true
}

# Get available AZs
data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 2)

  # Safe CIDR blocks (outside AWS default subnets)
  public_cidrs  = ["172.31.128.0/24", "172.31.129.0/24"]
  private_cidrs = ["172.31.130.0/24", "172.31.131.0/24"]
}

# Create public subnets
resource "aws_subnet" "public" {
  count                   = length(local.azs)
  vpc_id                  = data.aws_vpc.default.id
  cidr_block              = local.public_cidrs[count.index]
  availability_zone       = local.azs[count.index]
  map_public_ip_on_launch = true
  tags = {
    Name        = "rabbitmq-public-${local.azs[count.index]}"
    Environment = var.environment
  }
}

# Create private subnets
resource "aws_subnet" "private" {
  count             = length(local.azs)
  vpc_id            = data.aws_vpc.default.id
  cidr_block        = local.private_cidrs[count.index]
  availability_zone = local.azs[count.index]
  tags = {
    Name        = "rabbitmq-private-${local.azs[count.index]}"
    Environment = var.environment
  }
}

# Get default Internet Gateway
data "aws_internet_gateway" "default" {
  filter {
    name   = "attachment.vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Public route table
resource "aws_route_table" "public" {
  vpc_id = data.aws_vpc.default.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = data.aws_internet_gateway.default.id
  }
  tags = {
    Name        = "rabbitmq-public-rt"
    Environment = var.environment
  }
}

# Associate public subnets with public route table
resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Elastic IP for NAT
resource "aws_eip" "nat" {
  domain = "vpc"
  tags   = { Environment = var.environment }
}

# NAT Gateway in first public subnet
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id
  tags          = { Environment = var.environment }

  depends_on = [aws_subnet.public]
}

# Private route table
resource "aws_route_table" "private" {
  vpc_id = data.aws_vpc.default.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }
  tags = { Environment = var.environment }
}

# Associate private subnets with private route table
resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# Deploy RabbitMQ cluster
module "rabbitmq_cluster" {
  source = "./modules/rabbitmq-cluster"

  vpc_id          = data.aws_vpc.default.id
  public_subnets  = aws_subnet.public[*].id
  private_subnets = aws_subnet.private[*].id
  node_count      = var.rabbitmq_node_count
  instance_type   = var.instance_type
  ami_id          = data.aws_ssm_parameter.amazon_linux_2.value
  environment     = var.environment
  perform_instance_refresh = var.perform_instance_refresh
}