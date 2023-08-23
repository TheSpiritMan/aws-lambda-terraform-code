resource "aws_security_group" "lambda_sg" {
  name_prefix = "lambda-sg"
  vpc_id      = aws_vpc.all_vpc.id

  # Allow outbound traffic (required for Lambda to communicate with other services)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ec2_sg" {
  name_prefix = "ec2-sg"
  vpc_id      = aws_vpc.all_vpc.id

  # Allow inbound traffic only from the Lambda security group
  ingress {
    from_port       = 8000 # Update this to your desired port
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.lambda_sg.id]
  }
  # Allow inbound traffic from anywhere on port 22 (SSH)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allowing access from anywhere
  }

  # Allow outbound traffic for ports 80 and tcp protocols
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow outbound traffic for ports 443 and tcp protocols
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
