# state.tf
terraform {
  backend "s3" {
    bucket = "<your-terraform-state-bucket>"
    key    = "cross-os-docker-installation.tfstate"
    region = "us-east-1"
    encrypt = true
    use_lockfile = true
  }
}
