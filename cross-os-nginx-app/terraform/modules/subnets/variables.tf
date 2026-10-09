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
}

variable "vpc_id" {
  description = "Vpc id"
  type        = string
}

