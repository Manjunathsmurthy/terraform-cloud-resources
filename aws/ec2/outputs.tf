# AWS EC2 Outputs

output "instance_id" {
  description = "The ID of the EC2 instance"
  value       = aws_instance.web.id
}

output "instance_public_ip" {
  description = "Public IP address of the instance"
  value       = aws_eip.web.public_ip
}

output "instance_private_ip" {
  description = "Private IP address of the instance"
  value       = aws_instance.web.private_ip
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.web.id
}

output "eip_id" {
  description = "ID of the Elastic IP"
  value       = aws_eip.web.id
}
