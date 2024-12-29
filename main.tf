resource "aws_vpc" "emu_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "dev-vpc"
  }
}

resource "aws_subnet" "emu_subnet" {
  vpc_id                  = aws_vpc.emu_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-west-2a"


  tags = {
    Name = "dev-public-subnet"
  }
}

resource "aws_internet_gateway" "emu_igw" {
  vpc_id = aws_vpc.emu_vpc.id

  tags = {
    Name = "dev-igw"
  }
}

resource "aws_route_table" "emu_route_table" {
  vpc_id = aws_vpc.emu_vpc.id

  tags = {
    Name = "dev-route-table"
  }
}

resource "aws_route" "emu_default_rt" {
  route_table_id         = aws_route_table.emu_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.emu_igw.id
}

resource "aws_route_table_association" "emu_subnet_association" {
  subnet_id      = aws_subnet.emu_subnet.id
  route_table_id = aws_route_table.emu_route_table.id
}

resource "aws_security_group" "emu_sg" {
  name        = "dev-sg"
  vpc_id      = aws_vpc.emu_vpc.id
  description = "dev-security-group"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/32"] #Add your IP here
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

resource "aws_key_pair" "emu_auth" {
  key_name   = "emu-key"
  public_key = file("~/.ssh/terrakey.pub")
}

resource "aws_instance" "emu_instance" {
  ami                    = data.aws_ami.ubuntu_server.id
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.emu_auth.key_name
  subnet_id              = aws_subnet.emu_subnet.id
  vpc_security_group_ids = [aws_security_group.emu_sg.id]
  user_data              = file("userdata.tpl")

  tags = {
    Name = "dev-HelloWorld"
  }



  provisioner "local-exec" {
    command = templatefile("${var.host_os}-ssh-config.tpl", {
      hostname     = self.public_ip,
      user         = "ubuntu",
      identityfile = "~/.ssh/terrakey"
    })
    interpreter = var.host_os == "windows" ? ["Powershell", "-Command"] : ["bash", "-c"]
  }


}