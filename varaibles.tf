variable "aws_region" {
    type        = string
    default     = "ap-south-1" 
}
variable "cluster_name" {
  default = "eks-cluster"
  type    = string
}
variable "private_subnet_ids" {
  type    = list(string)
  default = []
}
variable "access_key" {
  description = "AWS Access Key"
}

variable "secret_key" {
  description = "AWS Secret Access Key"
}
