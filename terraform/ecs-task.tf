// ECS Task Definition (blueprint)
resource "aws_ecs_task_definition" "app" {
  family                   = "mashroom-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name  = "mashroom-app"
      image = var.image
      portMappings = [
        {
          containerPort = var.container_port
          protocol      = "tcp"
        }
      ]
    }
  ])
}


// ECS Service
resource "aws_ecs_service" "app" {
  name             = "mashroom-service"
  cluster          = aws_ecs_cluster.main.id
  task_definition  = aws_ecs_task_definition.app.arn
  desired_count    = 2
  launch_type      = "FARGATE"
  platform_version = "LATEST"

  //attach the ALB to the ECS service
  load_balancer {
    target_group_arn = aws_lb_target_group.app_tg.arn
    container_name   = "mashroom-app"
    container_port   = 3000
  }

  network_configuration {
    subnets = [
      aws_subnet.private_a.id,
      aws_subnet.private_b.id
    ]
    security_groups  = [aws_security_group.app_sg.id]
    assign_public_ip = true
  }
}



// IAM Role for ECS task execution
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "mashroom-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_attach" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

// IAM Role for ECS task (task role); keep empty unless your app needs AWS permissions
resource "aws_iam_role" "ecs_task_role" {
  name = "mashroom-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

