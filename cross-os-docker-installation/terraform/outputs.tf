output "list_of_ec2" {
  description = "List of ec2 instance"
  value = module.ec2.ec2_instance_ips
}

output "sg" {
  value = module.sg.sg_ids
}


output "managed_sg" {
  value = module.sg.managed_security_group_ids
}