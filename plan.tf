terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region     = "eu-central-1"
  access_key = ""
  secret_key = ""
}

locals {
  rulesmap = {
    "HTTP" = {
      port        = 80,
      cidr_blocks = ["0.0.0.0/0"],
    }
    "SSH" = {
      port        = 22,
      cidr_blocks = ["0.0.0.0/0"],
    }
  }
  vpcs = [
    {
      name = "hub",
      cidr_block = "10.10.10.0/24"
    },
    {
      name = "east",
      cidr_block = "10.30.10.0/24"
    },
    {
      name = "west",
      cidr_block = "10.20.10.0/24"
    }
  ]
  subnets = [
    {
      az = "eu-central-1a",
      cidr = "10.10.10.0/28",
      parent = "hub"
    },
    {
      az = "eu-central-1b",
      cidr = "10.30.10.0/28",
      parent = "east"
    },
    {
      az = "eu-central-1c",
      cidr = "10.20.10.0/28",
      parent = "west"
    }
  ]
  routes = [
    {
      dest = "10.20.10.0/24" 
      gw = aws_vpc_peering_connection.westToHub.id
      rt = 0
    },
    {
      dest = "10.30.10.0/24" 
      gw = aws_vpc_peering_connection.eastToHub.id
      rt = 0
    },
    {
      dest = "10.10.10.0/24" 
      gw = aws_vpc_peering_connection.eastToHub.id
      rt = 1
    },
    {
      dest = "10.10.10.0/24" 
      gw = aws_vpc_peering_connection.westToHub.id
      rt = 2
    },
    {
      dest = "10.20.10.0/24" 
      gw = aws_vpc_peering_connection.eastToWest.id
      rt = 1
    },
    {
      dest = "10.30.10.0/24" 
      gw = aws_vpc_peering_connection.eastToWest.id
      rt = 2
    }
  ]
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_vpc" "myvpc" {
  for_each = {
    for index, vpc in local.vpcs: index => vpc
  }
  cidr_block = each.value.cidr_block
  instance_tenancy     = "default"
  tags = {
    Name = each.value.name,
    Owner = "cpaggen"
  }
}

resource "aws_security_group" "sg" {
  for_each = aws_vpc.myvpc
  vpc_id = each.value.id

  dynamic "ingress" {
    for_each = local.rulesmap
    content {
      description = ingress.key # HTTP or SSH
      from_port   = ingress.value.port
      to_port     = ingress.value.port
      protocol    = "tcp"
      cidr_blocks = ingress.value.cidr_blocks
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "cpaggen-sg"
  }
}

resource "aws_subnet" "subnet" {
  for_each = {
    for index, subnet in local.subnets: index => subnet
  }
  cidr_block = each.value.cidr
  availability_zone = each.value.az
  vpc_id                  = aws_vpc.myvpc[each.key].id
  map_public_ip_on_launch = false
  tags = {
    Name = "subnet-${each.value.az}-${each.value.parent}"
  }
}

resource "aws_vpc_peering_connection" "eastToHub" {
  tags = {
    Name = "east-to-hub"
  }
  peer_vpc_id   = aws_vpc.myvpc[1].id
  vpc_id        = aws_vpc.myvpc[0].id
  auto_accept   = true
}

resource "aws_vpc_peering_connection" "westToHub" {
  tags = {
    Name = "west-to-hub"
  }
  peer_vpc_id   = aws_vpc.myvpc[2].id
  vpc_id        = aws_vpc.myvpc[0].id
  auto_accept   = true
}

resource "aws_vpc_peering_connection" "eastToWest" {
  tags = {
    Name = "east-to-west"
  }
  peer_vpc_id   = aws_vpc.myvpc[1].id
  vpc_id        = aws_vpc.myvpc[2].id
  auto_accept   = true
}

resource "aws_internet_gateway" "igw" {
  for_each = aws_vpc.myvpc
  vpc_id = each.value.id 
  tags = {
    Name = "igw-${each.value.tags_all.Name}"
  }
}

resource "aws_route_table" "rt" {
  for_each = aws_vpc.myvpc
  vpc_id = each.value.id
  tags   = {
    Name = "rt-${each.value.tags_all.Name}"
  }
}

resource "aws_route_table_association" "rtassoc" {
  count = length(local.subnets) 
  subnet_id      = aws_subnet.subnet[count.index].id
  route_table_id = aws_route_table.rt[count.index].id
}

resource "aws_route" "defaultRoutes" {
  count = length(aws_route_table.rt)
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw[count.index].id
  route_table_id         = aws_route_table.rt[count.index].id
}

resource "aws_route" "vpcRoutes" {
  for_each = {
    for index, route in local.routes: index => route
  }
  destination_cidr_block    = each.value.dest
  vpc_peering_connection_id = each.value.gw
  route_table_id            = aws_route_table.rt[each.value.rt].id
}

resource "aws_instance" "ec2" {
  count = length(local.vpcs)
  associate_public_ip_address = true
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t3.micro"
  key_name                    = "frankfurt-keypair-one"
  vpc_security_group_ids      = [aws_security_group.sg[count.index].id]
  subnet_id                   = aws_subnet.subnet[count.index].id
  provisioner "file" {
    source      = "./frankfurt-keypair-one.pem"
    destination = "~/frankfurt-key"
    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("frankfurt-keypair-one.pem")
      host        = self.public_ip
    }
   }

  tags = {
    Terraform   = "true"
    Environment = "dev"
    Name        = "cpaggen-terraform-${count.index}"
  }
}

output "instance_ip_addresses" {
  value = {
    for instance in aws_instance.ec2:
      instance.id => instance.private_ip
  }
}

output "instance_pubip_addresses" {
  value = {
    for instance in aws_instance.ec2:
      instance.id => instance.public_ip
  }
}
