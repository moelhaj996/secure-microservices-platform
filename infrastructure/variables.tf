variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-west-2"
}

variable "project_name" {
  description = "Name of the project, used as a prefix for all resources"
  type        = string
  default     = "secure-microservices"
}

variable "environment" {
  description = "Environment (staging or production)"
  type        = string
  default     = "staging"
}

variable "domain_name" {
  description = "Domain name for the application"
  type        = string
  default     = "api.yourdomain.com"
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.27"
}

variable "node_instance_type" {
  description = "EC2 instance type for the EKS nodes"
  type        = string
  default     = "t3.medium"
}

variable "min_nodes" {
  description = "Minimum number of nodes in the EKS cluster"
  type        = number
  default     = 1
}

variable "max_nodes" {
  description = "Maximum number of nodes in the EKS cluster"
  type        = number
  default     = 5
}

variable "desired_nodes" {
  description = "Desired number of nodes in the EKS cluster"
  type        = number
  default     = 3
} 