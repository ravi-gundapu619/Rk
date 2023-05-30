resource "tls_private_key" "ssh_key" {
  algorithm   = "RSA"
  rsa_bits    = 4096
}

output "private_key" {
  value = tls_private_key.ssh_key.private_key_pem
  sensitive = true

}

output "public_key" {
  value = tls_private_key.ssh_key.public_key_openssh
  sensitive = true
}

resource "aws_key_pair" "tf-key-pair" {
  key_name   = "tf-key-pair"
  public_key = tls_private_key.ssh_key.public_key_openssh
}

resource "local_file" "tf-key" {
  content  = tls_private_key.ssh_key.private_key_pem
  filename = "private-key-pair"
  file_permission = "0600"
}



resource "aws_instance" "mongodb_instance" {
  count = 3

  ami           = "ami-03a933af70fa97ad2"
  instance_type = "t2.micro"
  key_name      = "tf-key-pair"
  vpc_security_group_ids = [aws_security_group.mongodb.id]
  subnet_id = module.db-vpc.private_subnets[count.index % length(module.db-vpc.private_subnets)]

  tags = {
    Name = "mongodb-${count.index + 1}"
  }

}
resource "aws_instance" "bastion" {
  ami           = "ami-03a933af70fa97ad2"  # Replace with the appropriate AMI ID
  instance_type = "t2.micro"
  key_name      = aws_key_pair.tf-key-pair.key_name
  subnet_id     = module.db-vpc.public_subnets[0]
  vpc_security_group_ids = [aws_security_group.mongodb.id]

  tags = {
    Name = "bastion-host"
  }
}

resource "null_resource" "mongodb_provisioner" {
  
  depends_on = [
    aws_instance.mongodb_instance,
    aws_instance.bastion,
    module.db-vpc,
    aws_eks_cluster.devopsthehardway-eks,
    aws_eks_node_group.worker-node-group
  ]
  count = 3
  connection {
    type        = "ssh"
    user        = "ubuntu"
    bastion_host         = aws_instance.bastion.public_ip
    bastion_user         = "ubuntu"  # Replace with the appropriate SSH user for the bastion host
    bastion_private_key  = tls_private_key.ssh_key.private_key_pem
    agent       = false
    timeout     = "10m"
    host = aws_instance.mongodb_instance[count.index].private_ip
    private_key =  tls_private_key.ssh_key.private_key_pem
  }


  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y gnupg",
      "wget -qO - https://www.mongodb.org/static/pgp/server-5.0.asc | sudo apt-key add -",
      "echo 'deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu bionic/mongodb-org/5.0 multiverse' | sudo tee /etc/apt/sources.list.d/mongodb-org-5.0.list",
      "sudo apt-get update",
      "sudo apt-get install -y mongodb-org",
      "sudo sed -i 's/#replication:/replication:\\n  replSetName: \"myReplicaSet\"/g' /etc/mongod.conf",
      "sudo systemctl start mongod",
      "sudo systemctl enable mongod",
      "sudo sed -i 's/bindIp:/bindIp: ${aws_instance.mongodb_instance[count.index].private_ip},/' /etc/mongod.conf",
      "sudo systemctl restart mongod",
      "sleep 10",
      "mongo --eval 'rs.initiate({_id: \"myReplicaSet\", members: [{_id: 0, host: \"${aws_instance.mongodb_instance[0].private_ip}:27017\"}, {_id: 1, host: \"${aws_instance.mongodb_instance[1].private_ip}:27017\"}, {_id: 2, host: \"${aws_instance.mongodb_instance[2].private_ip}:27017\"}]});'"
   

     ]
  }
}


resource "null_resource" "copy_private_key" {
  depends_on = [
    aws_instance.mongodb_instance,
    aws_instance.bastion,
    module.db-vpc,
    aws_eks_cluster.devopsthehardway-eks,
    aws_eks_node_group.worker-node-group
  ]

  count = 1

  connection {
    type               = "ssh"
    user               = "ubuntu"
    bastion_host       = aws_instance.bastion.public_ip
    bastion_user       = "ubuntu"
    bastion_private_key = tls_private_key.ssh_key.private_key_pem
    agent              = false
    timeout            = "10m"
    host               = aws_instance.bastion.public_ip
    private_key        = tls_private_key.ssh_key.private_key_pem
  }

  provisioner "remote-exec" {
    inline = [
      "echo '${tls_private_key.ssh_key.private_key_pem}' > ~/private-key",
      "chmod 600 ~/private-key"
    ]
  }
}

resource "aws_security_group" "mongodb" {
  name_prefix = "mongodb-sg"

  vpc_id = module.db-vpc.vpc_id

  ingress {
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    protocol          = "icmp"
    from_port         = -1
    to_port           = -1
    cidr_blocks       = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]

  }

}
