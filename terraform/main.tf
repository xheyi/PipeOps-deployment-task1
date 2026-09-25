provider "aws" {
    region = "us-east-1"
}

resource "aws_vpc" "main" {
    cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "main" {
    vpc_id = aws_vpc.main.id
    cidr_block = "10.0.0.0/24"
}

resource "aws_internet_gateway" "main"{
    vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "main" {
    vpc_id = aws_vpc.main.id
    
    
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.main.id
    }
}

resource "aws_route_table_association" "main" {
    route_table_id = aws_route_table.main.id
    subnet_id = aws_subnet.main.id
}

resource "aws_security_group" "allow_http" {
    name = "allow http"
    vpc_id = aws_vpc.main.id

}

resource "aws_vpc_security_group_ingress_rule" "main" {
    security_group_id = aws_security_group.allow_http.id
    cidr_ipv4         = "0.0.0.0/0"
    from_port         = 80
    ip_protocol       = "tcp"
    to_port           = 80
}

resource "aws_vpc_security_group_egress_rule" "main" {
    security_group_id = aws_security_group.allow_http.id
    cidr_ipv4         = "0.0.0.0/0"
    ip_protocol       = "-1"
} 


resource "aws_eip" "main" {
    domain = "vpc"
}

resource "aws_eip_association" "main" {

    instance_id = aws_instance.main.id
    allocation_id = aws_eip.main.id
}

resource "aws_iam_role" "ec2_ssm_role" {
  name = "ec2-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ec2.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-ssm-profile"
  role = aws_iam_role.ec2_ssm_role.name
}

resource "aws_instance" "main" {
    instance_type = "t2.micro"
    subnet_id = aws_subnet.main.id
    ami = "ami-0b6d9d3d33ba97d99"

    iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

    vpc_security_group_ids = [
        aws_security_group.allow_http.id
    ]

}

output "instance_public_ip" {
    value = aws_instance.main.public_ip
}

output "instance_id" {
    value = aws_instance.main.id
}

output "elastic_ip" {
    value = aws_eip.main.public_ip
    
}

output "aws_iam_role_arn_ec2" {
    value = aws_iam_role.ec2_ssm_role.arn
}