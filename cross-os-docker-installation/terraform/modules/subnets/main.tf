resource "aws_subnet" "main" {
  for_each = var.subnet_objects
  vpc_id     = var.vpc_id
  cidr_block = each.value.cidr

  tags = each.value.tags
}




