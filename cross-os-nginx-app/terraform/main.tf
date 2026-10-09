
# vpc module
module "vpc" {
  source   = "./modules/vpc"
  vpc_cidr = var.vpc_cidr
  vpc_tag  = var.vpc_tag
}


# vpc subnets
module "subnets" {
  source         = "./modules/subnets"
  vpc_id         = module.vpc.vpc_id
  subnet_objects = var.subnet_objects
}

# Internet gateway
module "internet_gtw" {
  source = "./modules/internet-gtw"
  vpc_id = module.vpc.vpc_id
}


# Nat gateway (Only need when you want a private subnet)
# module "nat_gtw" {
#   source               = "./modules/nat-gtw"
#   nat_public_subnet_id = module.subnets.public_subnet_ids[0]
# }


locals {
  # Route tables
  route_tables_obj = {
    "public" = {
      name         = "public_rt"
      cidr         = "0.0.0.0/0"
      gateway_type = "igw"
      gateway_id   = module.internet_gtw.igw_id
    },
    # (Only need when you want a private subnet that should attached with a route table)
    # "private" = {
    #   name         = "private_rt"
    #   cidr         = "0.0.0.0/0"
    #   gateway_type = "nat"
    #   gateway_id   = module.nat_gtw.ngw_id
    # }
  }

  # Security group rules
  sg_rules = [
    {
      name = "managed-node-sg"
      rules = [
        {
          traffic_type = "ingress"
          description  = "Allow SSH Access"
          protocol     = "tcp"
          from_port    = 22
          to_port      = 22
          cidr_blocks  = ["0.0.0.0/0"]
        },
        {
          traffic_type = "ingress"
          description  = "Allow HTTP Access"
          protocol     = "tcp"
          from_port    = 80
          to_port      = 80
          cidr_blocks  = ["0.0.0.0/0"]
        },
        {
          traffic_type = "egress"
          description  = "Allow all outbound"
          protocol     = "-1"
          from_port    = 0
          to_port      = 0
          cidr_blocks  = ["0.0.0.0/0"]
        }
      ]
    },
    {
      name = "control-node-sg"
      rules = [
        {
          traffic_type = "ingress"
          description  = "Allow SSH Access"
          protocol     = "tcp"
          from_port    = 22
          to_port      = 22
          cidr_blocks  = ["0.0.0.0/0"]
        },
        {
          traffic_type = "egress"
          description  = "Allow all outbound"
          protocol     = "-1"
          from_port    = 0
          to_port      = 0
          cidr_blocks  = ["0.0.0.0/0"]
        }
      ]
    }
  ]
}

# Route table
module "route_tables" {
  source           = "./modules/route-tables"
  vpc_id           = module.vpc.vpc_id
  route_tables_obj = local.route_tables_obj
  subnet_map       = module.subnets.subnet_map
}


# Security Group
module "sg" {
  source   = "./modules/sg"
  vpc_id   = module.vpc.vpc_id
  sg_rules = local.sg_rules
}


# EC2

module "ec2" {
  source = "./modules/ec2"

  ec2_instance_data = {
    "control-ubuntu" = {
      subnet_id       = module.subnets.public_subnet_ids[0]
      security_groups = module.sg.managed_security_group_ids
      ami             = data.aws_ami.ubuntu.id
      instance_type   = "t3.micro"
      key             = module.ec2.key_name
      assoc_public_ip = true
      name            = "control-ubuntu"
      user            = "ubuntu"
      os_family       = "ubuntu"
      volume_size     = 15
    }

    "worker-ubuntu" = {
      subnet_id       = module.subnets.public_subnet_ids[1]
      security_groups = module.sg.managed_security_group_ids
      ami             = data.aws_ami.ubuntu.id
      instance_type   = "t3.micro"
      key             = module.ec2.key_name
      assoc_public_ip = true
      name            = "worker-ubuntu"
      user            = "ubuntu"
      os_family       = "ubuntu"
      volume_size     = 10
    }

    "worker-amazon" = {
      subnet_id       = module.subnets.public_subnet_ids[2]
      security_groups = module.sg.managed_security_group_ids
      ami             = data.aws_ami.amazon_linux.id
      instance_type   = "t3.micro"
      key             = module.ec2.key_name
      assoc_public_ip = true
      name            = "worker-amazon"
      user            = "ec2-user"
      os_family       = "amazon"
      volume_size     = 10
    }

    "worker-redhat" = {
      subnet_id       = module.subnets.public_subnet_ids[3]
      security_groups = module.sg.managed_security_group_ids
      ami             = data.aws_ami.redhat_linux.id
      instance_type   = "t3.micro"
      key             = module.ec2.key_name
      assoc_public_ip = true
      name            = "worker-redhat"
      user            = "ec2-user"
      os_family       = "redhat"
      volume_size     = 10
    }
  }

  ssh_key = var.ssh_key
}
