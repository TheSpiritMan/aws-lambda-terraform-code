resource "aws_key_pair" "ssdt_ec2_ssh_key" {
  key_name   = "ssdt_ec2_ssh_key"
  public_key = file(var.ssh_key_path) # Update the path to your public key file
}

resource "aws_instance" "ssdt_ec2" {
  ami                    = "ami-024e6efaf93d85776"
  instance_type          = "t2.micro" # Update to your desired instance type
  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  key_name                    = aws_key_pair.ssdt_ec2_ssh_key.key_name
  associate_public_ip_address = true # Assign a public IP address
  # You can customize other instance settings here

  tags = {
    Name = "ssdt_ec2" # Set the name of the instance
  }
  user_data = file("ec2-init.sh")
}

output "ec2_public_ip" {
  value       = aws_instance.ssdt_ec2.public_ip
  description = "Public IP address of EC2 instance"
}

output "ec2_private_ip" {
  value       = aws_instance.ssdt_ec2.private_ip
  description = "Private IP address of EC2 instance"
}