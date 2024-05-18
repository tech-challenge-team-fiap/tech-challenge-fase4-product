terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.40.0"
    }
  }

  required_version = ">= 1.0.0"
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

#ECS Setting
resource "aws_ecs_cluster" "tc_ms_product_cluster" {
  name = "tc-ms-product-cluster"
}
#ECS Setting

#DB Setting
resource "aws_db_instance" "db_product" {
  identifier           = "tech-challenge-product-db"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  allocated_storage    = 10
  db_name              = "tech_challenge_product_db"
  username             = "tech_challenge"
  password             = "tech_challenge-password"
  parameter_group_name = "default.mysql8.0"
  skip_final_snapshot  = true
  port                 = 3306
}
#DB Setting

#ECS Setting
locals {
  split_endpoint = element(split(":", aws_db_instance.db_product.endpoint), 0)
}

resource "aws_ecs_task_definition" "tech_challenge_product_task" {
  family                   = "tc-ms-product-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  cpu                      = "512"
  memory                   = "1024"

  container_definitions = jsonencode(
    [
      {
        name      = "ts-ms-product-container"
        image     = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/tc-ms-product:latest"
        cpu : 512,
        memory : 1024,
        essential : true,
        portMappings : [
          {
            containerPort : 8080,
            hostPort : 8080
          }
        ],
        environment = [
          { name = "PORT", value = "8080" },
          { name = "DB_NAME", value = aws_db_instance.db_product.db_name },
          { name = "DB_HOST", value = local.split_endpoint },
          { name = "DB_PORT", value = "${tostring(aws_db_instance.db_product.port)}" },
          { name = "DB_USERNAME", value = aws_db_instance.db_product.username },
          { name = "DB_PASSWORD", value = "${aws_db_instance.db_product.username}-password" },
          { name = "NODE_ENV", value = "dev" },

        ]
      }
    ]
  )
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecs_task_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Effect = "Allow"
      },
    ]
  })
}
#ECS Setting

resource "aws_security_group" "tc_ms_product_sg" {
  name        = "tc-ms-product-sg"
  description = "Allow all inbound traffic"
  vpc_id      = "vpc-0bd1f59a1daae83c1"  # Consider dynamic retrieval

  ingress {
    description      = "Allow all inbound traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    description      = "Allow all outbound traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
}
