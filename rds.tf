# Configured AWS provider with proper credentials
provider "aws" {
  region  = "ap-south-1"
  profile = "terraform-user"
}

# Create default VPC if one does not exist
resource "aws_default_vpc" "default_vpc" {
  tags = {
    Name = "default vpc"
  }
}

# Use data source to get all availability zones in the region
data "aws_availability_zones" "available_zones" {}

# Create a default subnet in the first availability zone
resource "aws_default_subnet" "subnet_az1" {
  availability_zone = data.aws_availability_zones.available_zones.names[0]
}

# Create a default subnet in the second availability zone
resource "aws_default_subnet" "subnet_az2" {
  availability_zone = data.aws_availability_zones.available_zones.names[1]
}

# Create security group for the web server
resource "aws_security_group" "webserver_security_group" {
  name        = "webserver security group"
  description = "enable HTTP access on port 80"
  vpc_id      = aws_default_vpc.default_vpc.id

  ingress {
    description = "HTTP access"
    from_port   = 80   
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "webserver security group"
  }
}

# Create security group for the database
resource "aws_security_group" "database_security_group" {
  name        = "database_security_group"
  description = "Allow inbound traffic for RDS PostgreSQL"

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "database security group"
  }
}

# Create the subnet group for the RDS instance (with 2 subnets for AZ coverage)
resource "aws_db_subnet_group" "database_subnet_group" {
  name        = "database-subnets"
  subnet_ids  = [aws_default_subnet.subnet_az1.id, aws_default_subnet.subnet_az2.id]
  description = "Subnets for database instance in multiple availability zones"

  tags = {
    Name = "database-subnets"
  }
}

# Create the RDS instance (single AZ for Free Tier but using 2 AZs in subnet group)
resource "aws_db_instance" "db_instance" {
  engine                  = "postgres"
  engine_version          = "16.3"
  identifier              = "my-postgres-db"      
  username                = "postgres"
  password                = "Sampathkumar"
  instance_class          = "db.t3.micro"
  allocated_storage       = 20
  db_subnet_group_name    = aws_db_subnet_group.database_subnet_group.name
  vpc_security_group_ids  = [aws_security_group.database_security_group.id]
  availability_zone       = data.aws_availability_zones.available_zones.names[0]  # Single AZ for Free Tier
  db_name                 = "database2"      
  skip_final_snapshot     = true
  publicly_accessible     = true 
}
