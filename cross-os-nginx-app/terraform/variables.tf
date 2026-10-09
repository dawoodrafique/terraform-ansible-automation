# Ami data of ubuntu, amazon-linux and redhut linux
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}


data "aws_ami" "amazon_linux" {
  most_recent = true

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["137112412989"] # Amazon
}


data "aws_ami" "redhat_linux" {
  most_recent = true

  filter {
    name   = "name"
    values = ["RHEL-9.*_HVM-*-x86_64-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["309956199498"] # Red Hat
}


variable "vpc_cidr" {
  description = "Vpc cidr"
  type        = string
  default     = "10.0.0.0/16"
}

variable "vpc_tag" {
  description = "Vpc tag"
  type        = string
  default     = "main"
}


variable "subnet_objects" {
  description = "Subnet cidr values and names"
  type = map(object(
    {
      cidr = string
      tags = object(
        {
          Name    = string
          type = string
        }
      )
    }
  ))

  default = {
    "public-1a" = {
      cidr = "10.0.1.0/24"
      tags = {
        Name    = "public-1a-subnet"
        type = "public"
      }
    },
    "public-1b" = {
      cidr = "10.0.2.0/24"
      tags = {
        Name    = "public-1b-subnet"
        type = "public"
      }
    },
    "public-1c" = {
      cidr = "10.0.3.0/24"
      tags = {
        Name    = "public-1c-subnet"
        type = "public"
      }
    },
    "public-1d" = {
      cidr = "10.0.4.0/24"
      tags = {
        Name    = "public-1d-subnet"
        type = "public"
      }
    }
  }
}




# variable "ec2_instance_data" {
#   description = "Ec2 instance data"
#   type = map(object(
#     {
#       subnet_id       = string
#       security_groups = set(string)
#       ami             = string
#       instance_type   = string
#       key             = string
#       assoc_public_ip = bool
#       name            = string
#       volume_size     = number
#     }
#   ))

#   default = {
#     "control-node" = {
#       subnet_id       = output.private_subnet_ids[0]
#       security_groups = output.control_security_group_ids
#       instance_type   = data.aws_ami.ubuntu.id
#       key             = "tf-ansible-key"
#       assoc_public_ip = false
#       name            = "control-node"
#       volume_size     = 15
#     },
#     "managed-node-1" = {
#       subnet_id       = output.public_subnet_ids[0]
#       security_groups = output.managed_security_group_ids
#       instance_type   = data.aws_ami.ubuntu.id
#       key             = "tf-ansible-key"
#       assoc_public_ip = true
#       name            = "controle-node"
#       volume_size     = 10
#     },
#     "managed-node-2" = {
#       subnet_id       = output.public_subnet_ids[1]
#       security_groups = output.managed_security_group_ids
#       instance_type   = data.aws_ami.amazon_linux.id
#       key             = "tf-ansible-key"
#       assoc_public_ip = true
#       name            = "managed-node-2"
#       volume_size     = 10
#     },
#     "managed-node-3" = {
#       subnet_id       = output.public_subnet_ids[2]
#       security_groups = output.managed_security_group_ids
#       instance_type   = data.aws_ami.redhat_linux.id
#       key             = "tf-ansible-key"
#       assoc_public_ip = true
#       name            = "managed-node-3"
#       volume_size     = 10
#     }
#   }
# }

variable "ssh_key" {
  description = "Ssh key data"
  type = object({
    key_name            = string
    public_key_location = string
  })

  default = {
    key_name            = "tf-ansible-key"
    public_key_location = "~/.ssh/tf-ansible-key.pub"
  }
}
