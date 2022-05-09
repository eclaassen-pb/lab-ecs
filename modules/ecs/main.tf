data "aws_iam_policy_document" "ecs_task_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "${var.ecs_naming_prefix}-ecs-task-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role_policy.json
}

resource "aws_iam_role_policy" "ecs-task-execution-policy" {
  name   = "${var.ecs_naming_prefix}-ecs-task-execution-policy"
  role   = aws_iam_role.ecs_task_execution_role.id
  policy = file("ecs-task-executionpolicy.json")
}

#ECS role for Ec2 instance

data "aws_iam_policy_document" "instance_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_ec2_role" {
  name               = "${var.ecs_naming_prefix}-ecs-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.instance_assume_role_policy.json
}

resource "aws_iam_role_policy" "ecs_policy" {
  name = "${var.ecs_naming_prefix}-ecs-ec2-policy"
  role = aws_iam_role.ecs_ec2_role.id
  policy = file("ecs-ec2-policy.json")
}

  resource "aws_iam_instance_profile" "ecs_ec2_profile" {
  name = "${var.ecs_naming_prefix}-ecs-ec2-profile"
  role = aws_iam_role.ecs_ec2_role.name
}

resource "aws_ecs_cluster" "ecs_cluster" {
  name = "${var.ecs_naming_prefix}-ecs-cluster"
}
