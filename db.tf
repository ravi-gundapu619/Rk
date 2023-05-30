module "db-vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "db-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["ap-south-1a", "ap-south-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24", "10.0.4.0/24"]
  public_subnets  = ["10.0.5.0/24", "10.0.6.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = false
  one_nat_gateway_per_az = true
  reuse_nat_ips        = false
  enable_dns_hostnames = true
  enable_dns_support   = true
  map_public_ip_on_launch = true
  tags = {
    Terraform = "true"
    Environment = "dev"
  }
}
resource "aws_default_security_group" "db-vpc" {
  vpc_id = module.db-vpc.vpc_id

  ingress {
    protocol          = "icmp"
    from_port         = -1
    to_port           = -1
    cidr_blocks       = ["0.0.0.0/0"]
    
    }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
