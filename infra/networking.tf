resource "aws_vpc" "main" {
  #checkov:skip=CKV2_AWS_11:VPC flow logging not required for this exercise
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# Restrict default security group to deny all traffic
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.main.id

  # No ingress rules - deny all inbound traffic
  # No egress rules - deny all outbound traffic

  tags = {
    Name = "${var.project_name}-default-sg-restricted"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

resource "aws_subnet" "public" {
  #checkov:skip=CKV2_AWS_11:Public subnets are used for load balancers, not instances
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.project_name}-public-subnet-${count.index + 1}"
    Type = "Public"
  }
}

resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 2)
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "${var.project_name}-private-subnet-${count.index + 1}"
    Type = "Private"
  }
}

# Firewall Subnets for Network Firewall endpoints
resource "aws_subnet" "firewall" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 4)
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "${var.project_name}-firewall-subnet-${count.index + 1}"
    Type = "Firewall"
  }
}

resource "aws_eip" "nat" {
  count  = 2
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-nat-eip-${count.index + 1}"
  }

  depends_on = [aws_internet_gateway.main]
}

resource "aws_nat_gateway" "main" {
  count         = 2
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name = "${var.project_name}-nat-gw-${count.index + 1}"
  }

  depends_on = [aws_internet_gateway.main]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

# Route from public subnets to Internet through firewall endpoint in first AZ
resource "aws_route" "public_to_firewall" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  vpc_endpoint_id        = element([for ss in tolist(aws_networkfirewall_firewall.main.firewall_status[0].sync_states) : ss.attachment[0].endpoint_id], 0)

  depends_on = [aws_networkfirewall_firewall.main]
}

resource "aws_route_table" "private" {
  count  = 2
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }

  tags = {
    Name = "${var.project_name}-private-rt-${count.index + 1}"
  }
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}
# Firewall Subnet Route Table - routes to IGW
resource "aws_route_table" "firewall" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-firewall-rt"
  }
}

resource "aws_route_table_association" "firewall" {
  count          = length(aws_subnet.firewall)
  subnet_id      = aws_subnet.firewall[count.index].id
  route_table_id = aws_route_table.firewall.id
}

# IGW Route Table - routes internet traffic to firewall endpoints
resource "aws_route_table" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw-rt"
  }
}

# Route from IGW to public subnets through firewall
resource "aws_route" "igw_to_firewall" {
  count                  = length(var.availability_zones)
  route_table_id         = aws_route_table.igw.id
  destination_cidr_block = aws_subnet.public[count.index].cidr_block
  vpc_endpoint_id        = element([for ss in tolist(aws_networkfirewall_firewall.main.firewall_status[0].sync_states) : ss.attachment[0].endpoint_id], count.index)

  depends_on = [aws_networkfirewall_firewall.main]
}

# Associate IGW route table with the Internet Gateway
resource "aws_route_table_association" "igw" {
  gateway_id     = aws_internet_gateway.main.id
  route_table_id = aws_route_table.igw.id
}
