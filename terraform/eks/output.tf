output "eks_cluster_name" {
  description = "Name of the EKS Cluster"
  value       = aws_eks_cluster.eks_cluster.name
}

output "eks_cluster_endpoint" {
  description = "Endpoint for the EKS Cluster"
  value       = aws_eks_cluster.eks_cluster.endpoint
}

output "eks_cluster_arn" {
  description = "ARN of the EKS Cluster"
  value       = aws_eks_cluster.eks_cluster.arn
}

output "eks_cluster_version" {
  description = "Version of the EKS Cluster"
  value       = aws_eks_cluster.eks_cluster.version
}

output "control_plane_security_group_id" {
  description = "Security Group ID for the EKS Control Plane"
  value       = aws_security_group.control_plane_security_group.id
}

output "worker_node_security_group_id" {
  description = "Security Group ID for Worker Nodes"
  value       = aws_security_group.worker_node_security_group.id
}


output "worker_node_group_name" {
  description = "Name of the Worker Node Group"
  value       = aws_eks_node_group.worker_node_group.node_group_name
}

output "worker_node_instance_type" {
  description = "Instance type for Worker Nodes"
  value       = var.worker_node_instance_type
}