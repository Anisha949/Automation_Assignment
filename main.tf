/*===Configuration===*/


/*Defining AWS as our provider*/

provider "aws" {
  region = "${var.aws_region}"
}

/*Defining our VPC*/

resource "aws_vpc" "default" {
  cidr_block = "${var.vpc_cidr}"
  enable_dns_hostnames = true

  tags {
    Name = "ques1-vpc"
  }
}

/*Defining the public subnet*/

resource "aws_subnet" "public-subnet" {
  vpc_id            = "${aws_vpc.default.id}"
  cidr_block        = "${var.public_subnet_cidr}"
  availability_zone = "us-east-1a"

  tags {
    Name = "ques1-Public Subnet"
  }
}

/*Defining elastic IP for NAT*/

resource "aws_eip" "nat_eip" {
  vpc      = true
  /*depends_on = ["aws_internet_gateway.gw.id"]*/
}



/*Configuring NAT for the private subnet*/

resource "aws_nat_gateway" "nat" {
  allocation_id = "${aws_eip.nat_eip.id}"
  subnet_id = "${aws_subnet.public-subnet.id}"
  /*depends_on = ["aws_internet_gateway.gw.id"]*/
}

/*Creating private route table*/

resource "aws_route_table" "priv-route-table" {
  vpc_id = "${aws_vpc.default.id}"

  tags{
     Name = "Private route table"
  }
}

resource "aws_route" "private-route"{
  route_table_id  = "${aws_route_table.priv-route-table.id}"
  egress_only_gateway_id = "${aws_internet_gateway.gw.id}"
  nat_gateway_id = "${aws_nat_gateway.nat.id}"

}

/*Defining the private subnet*/

resource "aws_subnet" "private_subnet"{
  count  = "${length(var.aws_zones)}"
  vpc_id = "${aws_vpc.default.id}"
  cidr   = "${cidrsubnet(var.private_subnet_cidr, 8, count.index)}"
  availability_zone = "${var.aws_zones[count.index]}"
  map_public_ip_on_launch = false

}


/*Associate subnet private_1_subnet_eu_west_1a to private route table*/

resource "aws_route_table_association" "priv-association" {
    subnet_id = "${aws_subnet.private_subnet.*.id}"
    route_table_id = "${aws_route_table.priv-route-table.id}"
}

/*Creating the Internet Gateway*/

resource "aws_internet_gateway" "gw" {
vpc_id = "${aws_vpc.default.id}"

  tags {
    Name = "VPC IGW"
  }
}

/*Creating a route table for public subnet to access the internet*/

resource "aws_route_table" "web-public-rt" {
  vpc_id = "${aws_vpc.default.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }

  tags {
    Name = "Public Subnet RT"
  }
}

/*Assign the route table to the public subnet*/

resource "aws_route_table_association" "web-public-rt" {
  subnet_id = "${aws_subnet.public-subnet.id}"
  route_table_id = "${aws_route_table.web-public-rt.id}"
}

/*Defining security group for public subnet*/

resource "aws_security_group" "sgweb" {
  name = "vpc_test_web"
  description = "Allow incoming HTTP connections & SSH access"

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = -1
    to_port = -1
    protocol = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks =  ["0.0.0.0/0"]
  }

  vpc_id="${aws_vpc.default.id}"

  tags {
    Name = "Web Server SG"
  }
}

/*Define SSH key pair for our instances*/

resource "aws_key_pair" "default" {
  key_name = "vpctestkeypair"
  public_key = "${file("${var.key_path}")}"
}


/*Defining EC2 instance inside the public subnet*/

resource "aws_instance" "wb-pub" {
   ami  = "${var.ami}"
   instance_type = "${var.instance_type}"
   key_name = "${aws_key_pair.default.id}"
   subnet_id = "${aws_subnet.public-subnet.id}"
   vpc_security_group_ids = ["${aws_security_group.sgweb.id}"]
   associate_public_ip_address = true
   source_dest_check = false

  tags {
    Name = "webserver-1"
  }
}


/*Security group for private subnet*/


resource "aws_security_group" "db-sg" {
    name = "vpc_db"
    description = "Allow incoming database connections."

    ingress { # MySQL
        from_port = 3306
        to_port = 3306
        protocol = "tcp"
    }

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["${var.private_subnet_cidr}"]
    }
    ingress {
        from_port = -1
        to_port = -1
        protocol = "icmp"
        cidr_blocks = ["${var.private_subnet_cidr}"]
    }

    egress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    vpc_id = "${aws_vpc.default.id}"

    tags {
        Name = "DBServerSG"
    }
}

/*Defining EC2 instance inside the private subnet*/

resource "aws_instance" "wb-priv" {
   ami  = "${var.ami}"
   instance_type = "${var.instance_type}"
   key_name = "${aws_key_pair.default.id}"
   subnet_id = "${aws_subnet.private_subnet.0.id}"
   vpc_security_group_ids = ["${aws_security_group.db-sg.id}"]
   associate_public_ip_address = false
   source_dest_check = false

  tags {
    Name = "webserver-2"
  }

  provisioner "file" {
    source      = "libraries.sh"
    destination = "/tmp/libraries.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/libraries.sh",
      "/tmp/libraries.sh args",
    ]
  }

  provisioner "file" {
    source      = "libraries.sh"
    destination = "/tmp/script.py"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/script.py",
      "/tmp/script.py args",
    ]
  }

}

/*Creating the RDS instance subnet groups*/

resource "aws_db_subnet_group" "rds_group" {
  name = "rds_subnet"
  description = "Terraform for RDS subnet group"
  subnet_ids = ["${aws_subnet.private_subnet.1.id}","{$aws_subnet.private_subnet.2.id}"]      

}

/*Creating security groups for RDS instance*/
resource "aws_security_group" "sg-rds" {
  name = "rds-security-group"
  description = "Creating security groups for RDS"
  vpc_id = "${aws_vpc.default.id}"

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = ["${aws_security_group.db-sg.id}"]
  }
 
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags {
    Name = "terraform-example-rds-security-group"
  }
}

/*Creating RDS instance*/
resource "aws_db_instance" "rds-instance" {
  identifier = "${var.rds_identifier}"
  allocated_storage = 5
  engine = "mysql"
  engine_version = "5.6.35"
  instance_class = "db.t2.micro"
  name                      = "${var.database_name}"
  username                  = "${var.database_user}"
  password                  = "${var.database_password}"
  db_subnet_group_name      = "${aws_db_subnet_group.rds_group.id}"
  vpc_security_group_ids    = ["${aws_security_group.sg-rds.id}"]
  skip_final_snapshot       = true
  final_snapshot_identifier = "Ignore"
}

/*Defining primary zone for Route53*/

resource "aws_route53_zone" "primary" {
  zone_id = "example.com"
}


/*Route53 settings*/

resource "aws_route53_record" "database" {
  zone_id = "${aws_route53_zone.primary.zone_id}"
  name = "database.example.com"
  type = "CNAME"
  ttl = "300"
  records = ["${aws_db_instance.rds-instance.address}"]
}





