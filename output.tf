output "vpc_id" {
  value = aws_vpc.my_vpc.id
}

output "subnet_ids" {
  value = aws_subnet.public_subnet[*].id
}

output "nlb_dns_name" {
  value = aws_lb.nlb.dns_name
}

output "target_group_arn" {
  value = aws_lb_target_group.target_group.arn
}

output "instance_ids" {
  value = aws_instance.my_instance[*].id
}
