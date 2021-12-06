output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "public_subnet_ids" {
  value = aws_subnet.public_subnets[*].id
}

output "private_subnet_container_ids" {
  value = aws_subnet.private_container_subnets[*].id
}

output "private_subnet_db_ids" {
  value = aws_subnet.private_db_subnets[*].id
}
