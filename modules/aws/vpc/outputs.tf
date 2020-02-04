output "vpc_id" { value = aws_vpc.my_vpc.id }
output "private_subnet_ids" { value = aws_subnet.private_subnets.*.id }
output "public_subnet_ids" { value = aws_subnet.public_subnets.*.id }
