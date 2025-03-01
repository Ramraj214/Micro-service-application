output "jenkins_master_public_ip" {
  description = "Public IP of the Jenkins Master instance"
  value       = aws_instance.jenkins_master.public_ip
}

output "jenkins_slave_public_ips" {
  description = "Public IPs of the Jenkins Slave instances"
  value       = aws_instance.jenkins_slave[*].public_ip
}

