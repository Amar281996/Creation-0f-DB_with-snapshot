provider "aws" {
  region = var.region
  profile = "default"
}

data "aws_availability_zones" "available" {}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.77.0"

  name                 = "mydatabase"
  cidr                 = "10.0.0.0/16"
  azs                  = data.aws_availability_zones.available.names
  public_subnets       = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  enable_dns_hostnames = true
  enable_dns_support   = true
}

resource "aws_db_subnet_group" "sql_sub" {
  name       = "mydatabase"
  subnet_ids = module.vpc.public_subnets

  tags = {
    Name = "mydatabase"
  }
}

resource "aws_security_group" "rds" {
  name   = "education_rds"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "education_rds"
  }
}
resource "aws_db_instance" "rds_database" {
  identifier             = "rds-terraform"
  instance_class         = "db.t2.micro"
  allocated_storage      = 5
  engine                 = "mysql"
  engine_version         = "8.0.27"
  db_name                = "kia"
  username               = "amar"
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.sql_sub.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = true
  skip_final_snapshot    = true
# parameter_group_name    = "default.mysql8.0"
}
resource "aws_kms_key" "rds_database" {
  description = "Encryption key for automated backups"
}

resource "aws_db_snapshot" "test" {
  db_instance_identifier = aws_db_instance.rds_database.id
  db_snapshot_identifier = "testsnapshot1234"
#  kms_key_id             = aws_kms_key.rds_database.arn 
}