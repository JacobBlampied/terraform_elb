provider "aws" {
  region = "eu-west-1"
}

resource "aws_instance" "app_jacob" {
  ami = "ami-043d367a42b576573"
  instance_type = "t2.micro"
  subnet_id = "${aws_subnet.public_subnet_jacob.id}"
  vpc_security_group_ids = ["${aws_security_group.jacob_public_SG.id}"]
  user_data = "${data.template_file.app_init.rendered}"
  key_name = "DevOpsStudents"
  tags {
    Name = "app-jacob"
  }
}
resource "aws_instance" "db_jacob" {
  ami = "ami-052d4b45126cc68ec"
  instance_type = "t2.micro"
  subnet_id = "${aws_subnet.private_subnet_jacob.id}"
  vpc_security_group_ids = ["${aws_security_group.jacob_private_SG.id}"]
  user_data = "${data.template_file.db_init.rendered}"
  key_name = "DevOpsStudents"
  tags {
    Name = "db-jacob"
  }
}


resource "aws_subnet" "public_subnet_jacob" {
  vpc_id     = "vpc-02ee46f22955a5b81"
  cidr_block = "10.0.18.0/24"
  map_public_ip_on_launch = true
  availability_zone = "eu-west-1a"
  tags {
    Name = "public-subnet-jacob"
  }
}
resource "aws_subnet" "private_subnet_jacob" {
  vpc_id     = "vpc-02ee46f22955a5b81"
  cidr_block = "10.0.22.0/24"
  availability_zone = "eu-west-1a"

  tags {
    Name = "private-subnet-jacob"
  }
}


resource "aws_security_group" "jacob_public_SG" {
  name        = "jacob_public_SG"
  description = "Allow traffic"
  vpc_id      = "vpc-02ee46f22955a5b81"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "6"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "6"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
  tags {
    Name = "jacob_public_SG"
  }
}
resource "aws_security_group" "jacob_private_SG" {
  name        = "jacob_private_SG"
  description = "Allow traffic"
  vpc_id      = "vpc-02ee46f22955a5b81"


  ingress {
    from_port   = 27017
    to_port     = 27017
    protocol    = "6"
    cidr_blocks = ["10.0.11.0/24"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "6"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
  tags {
    Name = "jacob__private_SG"
  }
}


resource "aws_route_table" "public" {
  vpc_id = "vpc-02ee46f22955a5b81"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${data.aws_internet_gateway.default.id}"
  }

  tags {
    Name = "jacob_public_RT"
  }
}
resource "aws_route_table" "private" {
  vpc_id = "vpc-02ee46f22955a5b81"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${data.aws_internet_gateway.default.id}"
  }

  tags {
    Name = "jacob_private_RT"
  }
}

resource "aws_route_table_association" "public_rt_assoc_jacob" {
  subnet_id = "${aws_subnet.public_subnet_jacob.id}"
  route_table_id = "${aws_route_table.public.id}"
}
resource "aws_route_table_association" "private_rt_assoc_jacob" {
  subnet_id = "${aws_subnet.private_subnet_jacob.id}"
  route_table_id = "${aws_route_table.private.id}"
}

data "template_file" "app_init" {
  template = "${file("./scripts/app/init.sh.tpl")}"
  vars {
    db_host="mongodb://${aws_instance.db_jacob.private_ip}:27017/posts"
  }
}

data "aws_internet_gateway" "default" {
  filter {
    name = "attachment.vpc-id"
    values = ["vpc-02ee46f22955a5b81"]
  }
}

data "template_file" "db_init" {
  template = "${file("./scripts/db/init.sh.tpl")}"
}

resource "aws_lb" "test" {
  name               = "jacob-LB"
  internal           = false
  load_balancer_type = "network"
  subnets            = ["${aws_subnet.public_subnet_jacob.id}"]

  tags {
    Name = "jacob_LB"
  }
}

resource "aws_launch_configuration" "jacob_launch_config" {
  name = "jacob_launch_config"
  image_id = "ami-043d367a42b576573"
  instance_type = "t2.micro"
}

resource "aws_launch_template" "jacob_launch_template" {
  image_id = "ami-043d367a42b576573"
  instance_type = "t2.micro"
}

resource "aws_autoscaling_group" "jacob_launch_autoscale"{
  name = "test"
  availability_zones = ["eu-west-1a"]
  desired_capacity = 1
  max_size = 1
  min_size = 1
  tags {
    key = "name"
    value = "jacob_${count.index + 1}"
    propagate_at_launch = true
  }

  launch_template = {
    id = "${aws_launch_template.jacob_launch_template.id}"
    version = "$Latest"
  }
}
