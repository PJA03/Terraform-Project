locals {
  vpc_tags        = merge(var.required_tags, { Name = "${var.lastname}-vpc" })
  public_tags     = merge(var.required_tags, { Name = "${var.lastname}-public-subnet" })
  private_tags    = merge(var.required_tags, { Name = "${var.lastname}-private-subnet" })
  igw_tags        = merge(var.required_tags, { Name = "${var.lastname}-igw" })
  nat_tags        = merge(var.required_tags, { Name = "${var.lastname}-nat-gateway" })
  public_rt_tags  = merge(var.required_tags, { Name = "${var.lastname}-public-route-table" })
  private_rt_tags = merge(var.required_tags, { Name = "${var.lastname}-private-route-table" })
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

# Internet Gateway & NAT Gateway (One for the VPC as per diagram)
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = local.igw_tags
}

resource "aws_eip" "nat" {
  domain = "vpc"
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

  route {
    cidr_block = "0.0.0.0/0" //allow connection to the internet
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = local.public_rt_tags
}  

# Private RT
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id //for private subnets to get internet connection
  }

  tags = local.private_rt_tags
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