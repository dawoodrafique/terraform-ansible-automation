# 🏛️ Terraform Layer — Cross-OS Nginx App

> Provisions the complete AWS infrastructure and auto-generates the Ansible inventory so the configuration layer can run without any manual steps.

---

## 📑 Table of Contents

- [What This Layer Does](#-what-this-layer-does)
- [Prerequisites](#-prerequisites)
- [Directory Structure](#-directory-structure)
- [Module Breakdown](#-module-breakdown)
- [How Modules Wire Together](#-how-modules-wire-together)
- [Dynamic Inventory Generation](#-dynamic-inventory-generation)
- [Input Variables](#-input-variables)
- [Outputs](#-outputs)
- [Remote State](#-remote-state)
- [Usage](#-usage)

---

## 🔭 What This Layer Does

Running `terraform apply` in this directory will:

1. Create a **VPC** with public and optional private subnets
2. Attach an **Internet Gateway** for public subnet egress
3. Provision a **NAT Gateway** so private instances can reach the internet outbound
4. Configure **Route Tables** and their subnet associations
5. Create a **Security Group** allowing SSH (22) and HTTP (80) inbound
6. Launch one or more **EC2 instances** across the configured subnets
7. **Render `ansible/inventory.ini`** from a template with the real IPs of every provisioned host

After `apply` completes, the Ansible layer is ready to run with no additional setup.

---

## ✅ Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) ≥ 1.5
- [AWS CLI](https://aws.amazon.com/cli/) configured (`aws configure`) with permissions for EC2, VPC, and IAM
- An existing **EC2 key pair** in the target region
- (For team use) An **S3 bucket** and **DynamoDB table** for remote state — see [Remote State](#-remote-state)

---

## 📁 Directory Structure

```
terraform/
├── backend.tf                # Remote state — S3 bucket + DynamoDB lock table
├── inventory-generator.tf    # Renders ansible/inventory.ini using templatefile()
├── main.tf                   # Root module — calls all child modules
├── outputs.tf                # Exposes public/private IPs and other key values
├── provider.tf               # AWS provider configuration
├── README.md                 # ← You are here
├── variables.tf              # All input variable declarations
├── modules/
│   ├── ec2/                  # aws_instance — reusable for public and private hosts
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   ├── internet-gtw/         # aws_internet_gateway
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   ├── nat-gtw/              # aws_nat_gateway + aws_eip
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   ├── route-tables/         # aws_route_table + aws_route_table_association
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   ├── sg/                   # aws_security_group
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   ├── subnets/              # aws_subnet (public + private)
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   └── vpc/                  # aws_vpc
│       ├── main.tf
│       ├── outputs.tf
│       └── variables.tf
└── templates/
    └── inventory.tpl         # Ansible inventory Jinja2 template
```

---

## 🧩 Module Breakdown

Every AWS resource is encapsulated in a dedicated module. The root `main.tf` wires them together — outputs from one module feed as inputs to the next, forming a clean dependency chain with no hardcoded values.

| Module | Key Resources Created | Key Outputs |
|---|---|---|
| `vpc` | `aws_vpc` | `vpc_id` |
| `subnets` | `aws_subnet` × 2 | `public_subnet_id`, `private_subnet_id` |
| `internet-gtw` | `aws_internet_gateway` | `igw_id` |
| `nat-gtw` | `aws_nat_gateway`, `aws_eip` | `nat_gateway_id` |
| `route-tables` | `aws_route_table`, `aws_route_table_association` × 2 | `public_rt_id`, `private_rt_id` |
| `sg` | `aws_security_group` | `sg_id` |
| `ec2` | `aws_instance` | `public_ip`, `private_ip` |

---

## 🔗 How Modules Wire Together

The root `main.tf` passes outputs from upstream modules directly into downstream modules as inputs. No values are hardcoded — the dependency graph is explicit and automatically resolved by Terraform.

```
vpc
 └─► subnets         (receives vpc_id)
      └─► internet-gtw  (receives vpc_id)
      └─► nat-gtw       (receives public_subnet_id)
      └─► route-tables  (receives vpc_id, igw_id, nat_gateway_id,
      │                  public_subnet_id, private_subnet_id)
      └─► sg            (receives vpc_id)
      └─► ec2           (receives subnet_id, sg_id, ami_id, key_name)
```

The `ec2` module is intentionally called **twice** — once targeting the public subnet (bastion / web server) and once targeting the private subnet (optional workload host). This is the key reusability pattern of this layer.

---

## 📦 Dynamic Inventory Generation

`inventory-generator.tf` uses Terraform's built-in `templatefile()` function to render `templates/inventory.tpl` with the real EC2 IPs produced by the `ec2` module. The result is written directly to `../ansible/inventory.ini` via a `local_file` resource.

**Template** (`templates/inventory.tpl`): - [inventory.tpl](./templates/inventory.tpl)

**Result** (`ansible/inventory.ini`) — written automatically after `apply`:

```ini
[all:vars]
ansible_ssh_private_key_file=~/.ssh/tf-ansible-key
ansible_python_interpreter=/usr/bin/python3
ansible_host_key_checking=false


[servers]
# It has both control-ubuntu and the 
control-ubuntu ansible_host=54.173.x.x ansible_user=ubuntu
worker-ubuntu ansible_host=34.226.x.x ansible_user=ubuntu


worker-amazon ansible_host=100.27.x.x ansible_user=ec2-user


worker-redhat ansible_host=52.90.x.x ansible_user=ec2-user




```

No manual IP copy-paste is ever required.

---

## 📋 Input Variables

Defined in `variables.tf`. Override them via `terraform.tfvars` or `-var` flags on the CLI.

| Variable | Type | Default | Required | Description |
|---|---|---|---|---|
| `aws_region` | `string` | `"us-east-1"` | No | AWS region to deploy into |
| `vpc_cidr` | `string` | `"10.0.0.0/16"` | No | CIDR block for the VPC |
| `public_subnet_cidr` | `string` | `"10.0.1.0/24"` | No | CIDR for the public subnet |
| `private_subnet_cidr` | `string` | `"10.0.2.0/24"` | No | CIDR for the private subnet |
| `instance_type` | `string` | `"t3.micro"` | No | EC2 instance type |
| `key_name` | `string` | — | **Yes** | Name of an existing AWS EC2 key pair |
| `ami_id` | `string` | — | **Yes** | AMI ID to use for EC2 instances |

**Example `terraform.tfvars`:**

```hcl
aws_region   = "us-west-2"
key_name     = "my-keypair"
ami_id       = "ami-0abcdef1234567890"
instance_type = "t3.small"
```

---

## 📤 Outputs

Defined in `outputs.tf`. Visible after `terraform apply` and used by `inventory-generator.tf`.

| Output | Description |
|---|---|
| `public_ip` | Public IP of the bastion / control EC2 instance |
| `private_ip` | Private IP of the workload EC2 instance (if provisioned) |
| `vpc_id` | ID of the created VPC |

---

## 🗄️ Remote State

`backend.tf` is pre-configured for S3 remote state. Fill in your bucket name and table name before running in a shared environment:

```hcl
terraform {
  backend "s3" {
    bucket         = "your-terraform-state-bucket"
    key            = "cross-os-nginx-app/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "your-terraform-lock-table"
    encrypt        = true
  }
}
```

For solo local use, you can remove `backend.tf` entirely and state will be stored in `terraform.tfstate` locally.

---

## 🚀 Usage

```bash
# Move into the terraform directory
cd terraform

# Initialise providers and backend
terraform init

# Preview the execution plan
terraform plan -var "key_name=my-keypair" -var "ami_id=ami-0abc123"

# Apply — provisions all resources and writes ansible/inventory.ini
terraform apply -var "key_name=my-keypair" -var "ami_id=ami-0abc123" -auto-approve

# When you are done — destroys all provisioned resources
terraform destroy -auto-approve
```

> ⚠️ **Cost Warning:** The NAT Gateway accrues AWS charges by the hour even when no traffic flows through it. Always run `terraform destroy` when the environment is no longer needed.

---

*Part of the [Cross-OS Nginx App](../README.md) project.*