output "vpc_id" {
  description = "ID of the created VPC"
  value       = aws_vpc.this.id
}

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = aws_subnet.public.id
}

output "vpc_cidr_block" {
  description = "The VPC's CIDR block, useful for security group rules elsewhere"
  value       = aws_vpc.this.cidr_block
}
