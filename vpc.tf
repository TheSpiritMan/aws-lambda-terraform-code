resource "aws_vpc" "all_vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "all_subnet" {
  vpc_id     = aws_vpc.all_vpc.id
  cidr_block = "10.0.1.0/24"
}