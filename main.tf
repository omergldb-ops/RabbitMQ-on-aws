data "aws_vpc" "default" {
  default = true
}

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 2)
}

resource "aws_subnet" "public" {
  count                   = length(local.azs)
  vpc_id                  = data.aws_vpc.default.id
  cidr_block              = cidrsubnet("172.31.0.0/16", 8, count.index)
  availability_zone       = local.azs[count.index]
  map_public_ip_on_launch = true
  tags = {
    Name        = "rabbitmq-public-${local.azs[count.index]}"
    Environment = var.environment
  }
}

resource "aws_subnet" "private" {
  count             = length(local.azs)
  vpc_id            = data.aws_vpc.default.id
  cidr_block        = cidrsubnet("172.31.128.0/16", 8, count.index)
  availability_zone = local.azs[count.index]
  tags = {
    Name        = "rabbitmq-private-${local.azs[count.index]}"
    Environment = var.environment
  }
}

data "aws_internet_gateway" "default" {
  filter {
    name   = "attachment.vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_route_table" "public" {
  vpc_id = data.aws_vpc.default.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = data.aws_internet_gateway.default.id
  }
  tags = { Environment = var.environment }
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

module "rabbitmq_cluster" {
  source = "./modules/rabbitmq-cluster"

  vpc_id          = data.aws_vpc.default.id
  public_subnets  = aws_subnet.public[*].id
  private_subnets = aws_subnet.private[*].id
  node_count      = var.rabbitmq_node_count
  instance_type   = var.instance_type
  ami_id          = var.ami_id
  environment     = var.environment
}