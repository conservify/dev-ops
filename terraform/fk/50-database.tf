resource "aws_db_subnet_group" "fk" {
  name        = "${local.env}-db"
  description = "${local.env}-db"
  subnet_ids  = [ for key, value in local.network.azs: aws_subnet.private[key].id ]

  tags = {
    Name = local.env
  }
}

resource "aws_db_instance" "fk-database" {
  count                  = local.database.enabled ? 1 : 0

  engine                 = "postgres"
  identifier             = local.database.id
  allocated_storage      = local.database.allocated_storage
  engine_version         = local.database.engine_version
  instance_class         = local.database.instance
  username               = local.database.username
  password               = local.database.password
  db_subnet_group_name   = aws_db_subnet_group.fk.name
  vpc_security_group_ids = [ aws_security_group.db-server.id ]
  publicly_accessible    = false
  skip_final_snapshot    = true

  tags = {
    Name = local.env
  }
}
