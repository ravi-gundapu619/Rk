resource "aws_eks_cluster" "eks-cluster" {
 name = var.cluster_name
 role_arn = aws_iam_role.eks-iam-role.arn

 vpc_config {
  subnet_ids = module.main-vpc.public_subnets
 }

 depends_on = [
  aws_iam_role.eks-iam-role,
 ]
}
resource "aws_eks_node_group" "worker-node-group" {
  cluster_name  = aws_eks_cluster.eks-cluster.name
  node_group_name = "workernodegroup"
  node_role_arn  = aws_iam_role.workernodes.arn
  subnet_ids   = module.main-vpc.public_subnets
  instance_types = ["t2.micro"]

  scaling_config {
   desired_size = 2
   max_size   = 3
   min_size   = 1
  } 
  tags = {
    Name  = "workernodes"
  }

  depends_on = [
   aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
   aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
   #aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
  ]
}
resource "aws_iam_role" "eks-iam-role" {
 name = "devopsthehardway-eks-iam-role"

 path = "/"

 assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
  {
   "Effect": "Allow",
   "Principal": {
    "Service": "eks.amazonaws.com"
   },
   "Action": "sts:AssumeRole"
  }
 ]
}
EOF

}
resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy" {
 policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
 role    = aws_iam_role.eks-iam-role.name
}
resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly-EKS" {
 policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
 role    = aws_iam_role.eks-iam-role.name
}
resource "aws_iam_role" "workernodes" {
  name = "eks-node-group-example"

  assume_role_policy = jsonencode({
   Statement = [{
    Action = "sts:AssumeRole"
    Effect = "Allow"
    Principal = {
     Service = "ec2.amazonaws.com"
    }
   }]
   Version = "2012-10-17"
  })
 }

resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
 policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
 role    = aws_iam_role.workernodes.name
}
resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
 policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
 role    = aws_iam_role.workernodes.name
}

resource "aws_iam_role_policy_attachment" "EC2InstanceProfileForImageBuilderECRContainerBuilds" {
 policy_arn = "arn:aws:iam::aws:policy/EC2InstanceProfileForImageBuilderECRContainerBuilds"
 role    = aws_iam_role.workernodes.name
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
 policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
 role    = aws_iam_role.workernodes.name
}
resource "null_resource" "install_kubectl" {
  provisioner "local-exec" {
    command = <<-EOT
      sudo apt-get update && sudo apt-get install -y curl
      sudo apt install unzip
      curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
      unzip awscliv2.zip
      sudo ./aws/install
      curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
      chmod +x ./kubectl
      sudo mv ./kubectl /usr/local/bin/kubectl
      aws configure set aws_access_key_id "${var.access_key}"
      aws configure set aws_secret_access_key "${var.secret_key}"
      aws configure set region "${var.aws_region}"
      aws eks --region $(terraform output -raw region) update-kubeconfig --name $(terraform output -raw cluster_name)
    EOT
  }
  depends_on = [
    aws_eks_cluster.devopsthehardway-eks
  ]
}

