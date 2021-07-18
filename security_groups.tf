# Create a security group for load balancer - only TCP/80, TCP/443 and full outbound
resource "aws_security_group" "lb-sg" {
  provider    = aws.region-master
  name        = "lb-sg"
  description = "Allow 443 and traffic to jenkins SG"
  vpc_id      = aws_vpc.vpc_master.id
  ingress {
    description = "allow 443 from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "allow 80 from anywhere for redirection"
    from_port   = 80
    to_port     = 80
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

# Creating a SG for allowing TCP/8080 from anyone and TCP/22 from my IP in the us-east-1
resource "aws_security_group" "jenkins-sg" {
  provider    = aws.region-master
  name        = "jenkins-sg"
  description = "allow tcp/8080 and tcp/22"
  vpc_id      = aws_vpc.vpc_master.id
  ingress {
    description = "allow 22 from my pub ip"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.external-ip]
  }
  ingress {
    description     = "allow anyone on port 8080"
    from_port       = var.webserver-port
    to_port         = var.webserver-port
    protocol        = "tcp"
    security_groups = [aws_security_group.lb-sg.id]
  }
  ingress {
    description = "allow trafic from us-west-2"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["192.168.1.0/24"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create a SG for jenkins worker to allow tcp/22 from my ip in us-west-2
resource "aws_security_group" "jenkins-sg-oregon" {
  provider    = aws.region-worker
  name        = "jenkins-sg-oregon"
  description = "allowing tcp/22 and tcp/8080"
  vpc_id      = aws_vpc.vpc_master_oregon.id
  ingress {
    description = "allow 22 from my public ip"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.external-ip]
  }
  ingress {
    description = "allow trafic from us-east-1"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.1.0/24"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


