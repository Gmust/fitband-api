output "ec2_instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.app.id
}

output "ec2_public_ip" {
  description = "EC2 public IP address"
  value       = aws_instance.app.public_ip
}

output "ec2_public_dns" {
  description = "EC2 public DNS name"
  value       = aws_instance.app.public_dns
}

output "ec2_elastic_ip" {
  description = "EC2 Elastic IP (if allocated)"
  value       = var.allocate_elastic_ip ? aws_eip.app[0].public_ip : null
}

output "ec2_security_group_id" {
  description = "EC2 security group ID"
  value       = aws_security_group.ec2.id
}

output "ssh_command" {
  description = "SSH command to connect to EC2"
  value       = "ssh -i ~/.ssh/${aws_key_pair.app.key_name}.pem ubuntu@${aws_instance.app.public_ip}"
}

output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = var.create_rds ? aws_db_instance.main[0].endpoint : null
}

output "rds_port" {
  description = "RDS instance port"
  value       = var.create_rds ? aws_db_instance.main[0].port : null
}

output "rds_database_name" {
  description = "RDS database name"
  value       = var.create_rds ? aws_db_instance.main[0].db_name : null
}

output "rds_username" {
  description = "RDS master username"
  value       = var.create_rds ? aws_db_instance.main[0].username : null
}

output "database_url" {
  description = "PostgreSQL connection string (password not included)"
  value       = var.create_rds ? "postgresql://${aws_db_instance.main[0].username}:***@${aws_db_instance.main[0].endpoint}:${aws_db_instance.main[0].port}/${aws_db_instance.main[0].db_name}?schema=public" : null
  sensitive   = false
}

output "rds_security_group_id" {
  description = "RDS security group ID"
  value       = aws_security_group.rds.id
}

output "key_pair_name" {
  description = "SSH key pair name"
  value       = aws_key_pair.app.key_name
}

