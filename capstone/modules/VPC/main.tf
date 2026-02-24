/**
 * Module: Networking Layer (VPC)
 * Description: Establishes the fundamental network infrastructure, 
 * dividing the cloud environment into Public and Private zones for security isolation.
 *
 * Resources Created:
 * 1. VPC (Virtual Private Cloud):
 * - The isolated network container with DNS hostnames enabled for internal service discovery.
 *
 * 2. Subnets (Zonal Segmentation):
 * - Public Subnets: Hosted in multiple AZs. Attached to the Internet Gateway. Used for Load Balancers and Bastion Hosts.
 * - Private Subnets: Hosted in multiple AZs. Isolated from direct internet access. Used for App Servers.
 *
 * 3. Internet Gateway (IGW):
 * - The bridge allowing traffic to flow between the Public Subnets and the global internet.
 *
 * 4. NAT Gateway & Elastic IP (EIP):
 * - Placed in a Public Subnet (specifically index [1]).
 * - Function: Allows Private Subnet instances to initiate outbound connections (e.g., `yum update`) without accepting inbound connections.
 *
 * 5. Routing Infrastructure:
 * - Public Route Table: Routes 0.0.0.0/0 traffic to the Internet Gateway.
 * - Private Route Table: Routes 0.0.0.0/0 traffic to the NAT Gateway.
 */

locals {
  vpc_tags        = merge(var.required_tags, { Name = "${var.lastname}-vpc" })
  public_tags     = merge(var.required_tags, { Name = "${var.lastname}-public-subnet" })
  private_tags    = merge(var.required_tags, { Name = "${var.lastname}-private-subnet" })
  igw_tags        = merge(var.required_tags, { Name = "${var.lastname}-igw" })
  nat_tags        = merge(var.required_tags, { Name = "${var.lastname}-nat-gateway" })
  public_rt_tags  = merge(var.required_tags, { Name = "${var.lastname}-public-route-table" })
  private_rt_tags = merge(var.required_tags, { Name = "${var.lastname}-private-route-table" })
  nat_eip_tags    = merge(var.required_tags, { Name = "${var.lastname}-nat-eip" })
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  tags                 = local.vpc_tags
}

resource "aws_subnet" "public" {
  count             = length(var.public_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_cidrs[count.index]
  availability_zone = var.azs[count.index]
  tags              = local.public_tags
}

resource "aws_subnet" "private" {
  count             = length(var.private_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_cidrs[count.index]
  availability_zone = var.azs[count.index]
  tags              = local.private_tags
}

# Internet Gateway & NAT Gateway 
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = local.igw_tags
}

resource "aws_eip" "nat" {
  domain = "vpc"
  tags   = local.nat_eip_tags
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[1].id # on public subnet az-1b 
  tags          = local.nat_tags
}

# Route Tables
# Public RT
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id
  tags   = local.public_rt_tags
}

resource "aws_route" "internet_gateway" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}


# Private RT
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id
  tags   = local.private_rt_tags
}

resource "aws_route" "internet_access" {
  route_table_id         = aws_route_table.private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main.id
}


# Route Table Associations
resource "aws_route_table_association" "public_rta" {
  count          = length(var.public_cidrs)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "private_rta" {
  count          = length(var.private_cidrs)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private_rt.id
}