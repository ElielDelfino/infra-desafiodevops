resource "aws_security_group" "db" {
  name        = "db-sg"
  description = "Security group for database"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "db-sg"
  }

  depends_on = [aws_db_instance.this]
}

resource "aws_db_subnet_group" "this" {
  name       = "db-subnet-group"
  subnet_ids = var.private_subnet_ids

  depends_on = [aws_db_instance.this]
}

resource "aws_db_instance" "this" {
  identifier             = "app-postgres"
  allocated_storage      = var.db_allocated_storage
  engine                 = "postgres"
  engine_version         = "16.3"
  instance_class         = var.db_instance_type
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  apply_immediately      = true
  skip_final_snapshot    = true
  multi_az               = false
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.db.id]
  deletion_protection    = false
  publicly_accessible    = false
  backup_retention_period = 0
  auto_minor_version_upgrade = true

  tags = {
    Name = "app-postgres-db"
  }
}