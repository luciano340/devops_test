output "vpc_id" {
  value = aws_vpc.add_vpc.id
}

output "subnet_ids" {
  value = aws_subnet.add_subnets[*].id
}