output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.project_vpc.id
}

output "public_subnet1_id" {
  description = "The ID of the first public subnet"
  value       = aws_subnet.public_subnet1.id
}

output "public_subnet2_id" {
  description = "The ID of the second public subnet"
  value       = aws_subnet.public_subnet2.id
}

output "private_subnet1_id" {
  description = "The ID of the private subnet"
  value       = aws_subnet.private_subnet1.id
}

output "private_subnet2_id" {
  description = "The ID of the private subnet"
  value       = aws_subnet.private_subnet2.id
}

output "public_subnets" {
  value = [aws_subnet.private_subnet1.id, aws_subnet.private_subnet2.id]
}

output "private_subnets" {
  value = [aws_subnet.private_subnet1.id, aws_subnet.private_subnet2.id]
}

output "nat_gateway_id" {
  description = "The ID of the NAT gateway"
  value       = aws_nat_gateway.my_nat_gateway.id
}