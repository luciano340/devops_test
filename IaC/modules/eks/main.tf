#Cria um security group o qual irá permitir a saída de todo o tráfego e bloquear a entrada. 
resource "aws_security_group" "sg" {
  vpc_id = var.vpc_id
  egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
      prefix_list_ids = []
  }
  tags = {
      Name = "${var.prefix}-sg"
  }
}

#Cria uma nova role para a utilização no EKS
resource "aws_iam_role" "cluster" {
  name = "${var.cluster_name}-role"
  assume_role_policy = <<POLICY
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
POLICY
}

#Adiciona a politica a Role
resource "aws_iam_role_policy_attachment" "cluster-AmazonEKSVPCResourceController" {
  role = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
}

#Adiciona a politica a Role
resource "aws_iam_role_policy_attachment" "cluster-AmazonEKSClusterPolicy" {
  role = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

#Configura logs para o CloudWatch
resource "aws_cloudwatch_log_group" "log" {
  name = "/aws/eks-terraform/${var.cluster_name}/cluster"
  retention_in_days = var.retention_days
}

#Configurações do cluster
resource "aws_eks_cluster" "cluster" {
  name = "${var.cluster_name}"
  role_arn = aws_iam_role.cluster.arn
  enabled_cluster_log_types = ["api","audit"]

  #Configurações de vpc e security group
  vpc_config {
      subnet_ids = var.subnet_ids 
      security_group_ids = [aws_security_group.sg.id]
  }
  depends_on = [
    aws_cloudwatch_log_group.log,
    aws_iam_role_policy_attachment.cluster-AmazonEKSVPCResourceController,
    aws_iam_role_policy_attachment.cluster-AmazonEKSClusterPolicy,
  ]

  tags = {
      Name = "${var.prefix}-cluster"
  }

}

resource "aws_iam_role" "node" {
  name = "${var.cluster_name}-role-node"
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

#Adiciona a politica a Role
resource "aws_iam_role_policy_attachment" "node-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node.name
}

#Adiciona a politica a Role
resource "aws_iam_role_policy_attachment" "node-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node.name
}

#Adiciona a politica a Role
resource "aws_iam_role_policy_attachment" "node-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node.name
}

#Adiciona nodes ao cluster
resource "aws_eks_node_group" "add_nodes" {
  count = var.desired_cluster
  cluster_name = aws_eks_cluster.cluster.name
  node_group_name = "node-${count.index}"
  node_role_arn = aws_iam_role.node.arn
  subnet_ids = var.subnet_ids
  instance_types = var.instance_types

  #Configurações de auto scaling para o node
  scaling_config {
    desired_size = var.desired_size
    max_size = var.max_size
    min_size = var.min_size
  }
  
  depends_on = [
    aws_iam_role_policy_attachment.node-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.node-AmazonEC2ContainerRegistryReadOnly,
  ]

  tags = {
      Name = "${var.prefix}-${var.cluster_name}-node"
  }
}