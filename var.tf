/*===VARIABLES===*/

variable "aws_region" {
	description = "Region for the VPC"
	default = "us-east-1"
}


variable "vpc_cidr" {
	 description = "CIDR for the VPC"
	 default = "10.0.0.0/24"	
}


variable "public_subnet_cidr" {
	 description = "CIDR for the public subnet"
	 default = "10.0.1.0/24"
}


variable "private_subnet_cidr" {
	 description = "CIDR for the private subnet"
	 default = "10.0.2.0/24"
}


variable "ami" {
	 description = "Amazon Linux AMI"
	 default = "ami-4fffc834"
}

variable "instance_type" {
	 description = "Instance Type to be launched"
	 default = "t2.micro"
}


variable "key_path" {
  description = "SSH Public Key path"
  default = "/home/core/.ssh/id_rsa.pub"
}

variable "aws_zones" {
  type = "list"
  default = ["us-east-1a","us-east-1b","us-east-1c"]
}

variable "rds_identifier" {
  description = "Identify"
  default = "rds-identify"
}

variable "database_name" {
  default = "games-db"
}

variable "database_user" {
  default = "pe-training"
}

variable "database_password" { 
  default = "anisha"

}
