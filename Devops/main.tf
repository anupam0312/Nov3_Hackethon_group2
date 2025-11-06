###############################
# 1️⃣ Docker / Kubernetes Server
###############################

resource "aws_vpc" "docker_vpc" {
  cidr_block = "10.10.0.0/16"
  tags = { Name = "docker-vpc" }
}

resource "aws_subnet" "docker_subnet" {
  vpc_id                  = aws_vpc.docker_vpc.id
  cidr_block              = "10.10.1.0/24"
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "docker_igw" {
  vpc_id = aws_vpc.docker_vpc.id
}

resource "aws_route_table" "docker_rt" {
  vpc_id = aws_vpc.docker_vpc.id
}

resource "aws_route" "docker_route" {
  route_table_id         = aws_route_table.docker_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.docker_igw.id
}

resource "aws_route_table_association" "docker_rta" {
  subnet_id      = aws_subnet.docker_subnet.id
  route_table_id = aws_route_table.docker_rt.id
}

resource "aws_security_group" "docker_sg" {
  vpc_id = aws_vpc.docker_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "docker-sg" }
}

resource "aws_instance" "docker_instance" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = aws_subnet.docker_subnet.id
  vpc_security_group_ids = [aws_security_group.docker_sg.id]
  associate_public_ip_address = true

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y docker
    systemctl enable docker
    systemctl start docker
    curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x ./kubectl && mv ./kubectl /usr/local/bin/kubectl
  EOF

  tags = { Name = "docker-k8s-server" }
}

###############################
# 2️⃣ Jenkins Server
###############################

resource "aws_vpc" "jenkins_vpc" {
  cidr_block = "10.20.0.0/16"
  tags = { Name = "jenkins-vpc" }
}

resource "aws_subnet" "jenkins_subnet" {
  vpc_id                  = aws_vpc.jenkins_vpc.id
  cidr_block              = "10.20.1.0/24"
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "jenkins_igw" {
  vpc_id = aws_vpc.jenkins_vpc.id
}

resource "aws_route_table" "jenkins_rt" {
  vpc_id = aws_vpc.jenkins_vpc.id
}

resource "aws_route" "jenkins_route" {
  route_table_id         = aws_route_table.jenkins_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.jenkins_igw.id
}

resource "aws_route_table_association" "jenkins_rta" {
  subnet_id      = aws_subnet.jenkins_subnet.id
  route_table_id = aws_route_table.jenkins_rt.id
}

resource "aws_security_group" "jenkins_sg" {
  vpc_id = aws_vpc.jenkins_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "jenkins-sg" }
}

resource "aws_instance" "jenkins_instance" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = aws_subnet.jenkins_subnet.id
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]
  associate_public_ip_address = true

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    amazon-linux-extras install java-openjdk17 -y
    wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
    rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
    yum install -y jenkins
    systemctl enable jenkins
    systemctl start jenkins
  EOF

  tags = { Name = "jenkins-server" }
}

###############################
# 3️⃣ Grafana Server
###############################

resource "aws_vpc" "grafana_vpc" {
  cidr_block = "10.30.0.0/16"
  tags = { Name = "grafana-vpc" }
}

resource "aws_subnet" "grafana_subnet" {
  vpc_id                  = aws_vpc.grafana_vpc.id
  cidr_block              = "10.30.1.0/24"
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "grafana_igw" {
  vpc_id = aws_vpc.grafana_vpc.id
}

resource "aws_route_table" "grafana_rt" {
  vpc_id = aws_vpc.grafana_vpc.id
}

resource "aws_route" "grafana_route" {
  route_table_id         = aws_route_table.grafana_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.grafana_igw.id
}

resource "aws_route_table_association" "grafana_rta" {
  subnet_id      = aws_subnet.grafana_subnet.id
  route_table_id = aws_route_table.grafana_rt.id
}

resource "aws_security_group" "grafana_sg" {
  vpc_id = aws_vpc.grafana_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "grafana-sg" }
}

resource "aws_instance" "grafana_instance" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = aws_subnet.grafana_subnet.id
  vpc_security_group_ids = [aws_security_group.grafana_sg.id]
  associate_public_ip_address = true

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    cat <<EOT >> /etc/yum.repos.d/grafana.repo
    [grafana]
    name=grafana
    baseurl=https://packages.grafana.com/oss/rpm
    repo_gpgcheck=1
    enabled=1
    gpgcheck=1
    gpgkey=https://packages.grafana.com/gpg.key
    EOT
    yum install -y grafana
    systemctl enable grafana-server
    systemctl start grafana-server
  EOF

  tags = { Name = "grafana-server" }
}
