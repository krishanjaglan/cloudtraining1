provider "aws" {
  region = "us-east-2"
}

##############################################################
# Data sources to get VPC, subnets and security group details
##############################################################
data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "all" {
  vpc_id = data.aws_vpc.default.id
}

data "aws_security_group" "default" {
  vpc_id = data.aws_vpc.default.id
  name   = "default"
}

#####
# DB
#####
module "db" {
  source = "../../"

  identifier = "demodb-oracle"

  engine            = "oracle-se"
  engine_version    = "11.2.0.4.v22"
  instance_class    = "db.t3.micro"
  allocated_storage = 20
  storage_encrypted = false
  license_model     = "bring-your-own-license"

  # Make sure that database name is capitalized, otherwise RDS will try to recreate RDS instance every time
  name                                = "DEMODB"
  username                            = "something_like_user"
  password                            = "YourPwdShouldBeLongAndSecure!"
  port                                = "1521"
  iam_database_authentication_enabled = false

  vpc_security_group_ids = [data.aws_security_group.default.id]
  maintenance_window     = "Mon:00:00-Mon:03:00"
  backup_window          = "03:00-06:00"

  # disable backups to create DB faster
  backup_retention_period = 0

  tags = {
    Owner       = "user"
    Environment = "dev"
  }

  # DB subnet group
  subnet_ids = data.aws_subnet_ids.all.ids

  # DB parameter group
  family = "oracle-se-11.2"

  # DB option group
  major_engine_version = "11.2"

  # Snapshot name upon DB deletion
  final_snapshot_identifier = "demodb"

  # See here for support character sets https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Appendix.OracleCharacterSets.html
  character_set_name = "AL32UTF8"

  # Database Deletion Protection
  deletion_protection = false
}
