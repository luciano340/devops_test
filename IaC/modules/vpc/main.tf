#Criando VPC
resource "aws_vpc" "add_vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
      Name = "${var.prefix}-vpc"
  }
}

#Coleta as zonas de disponbilidade na região.
data "aws_availability_zones" "available" {}

#Adicionará as subnests, utilizando o count para economizar linhas, semelhanta a um loop com for/while
resource "aws_subnet" "add_subnets" {
  count = var.desired_subnets
  availability_zone = data.aws_availability_zones.available.names[count.index]
  vpc_id = aws_vpc.add_vpc.id
  cidr_block = "10.0.${count.index}.0/24"
  map_public_ip_on_launch = true
  tags = {
      Name = "${var.prefix}-subnet-${count.index}"
  }
}

#Adicionando o Internet Gateway a vpc
resource "aws_internet_gateway" "add_igw" {
  vpc_id = aws_vpc.add_vpc.id
  tags = {
      Name = "${var.prefix}-igw"
  }
}

#Adicionando RouterTable a vpc
resource "aws_route_table" "add_rtb" {
  vpc_id = aws_vpc.add_vpc.id
  route {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.add_igw.id
  }
  tags = {
      Name = "${var.prefix}-rtb"
  }
}

#Fazendo "ligação" entre as subnets e o Internet Gateway. Nesse momento tormamos a subnet publica.
resource "aws_route_table_association" "add_rtb_association" {
  count = var.desired_subnets
  route_table_id = aws_route_table.add_rtb.id
  subnet_id = aws_subnet.add_subnets.*.id[count.index]
}