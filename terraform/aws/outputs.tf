output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "private_subnet" {
  description = "First private subnet id"
  value       = module.vpc.private_subnets[0]
}

output "public_subnet" {
  description = "First public subnet id"
  value       = module.vpc.public_subnets[0]
}
