resource "aws_security_group" "efs" {
  name        = "${var.ecs_naming_prefix}-efs-sg"
  vpc_id      = var.ecs_vpc_id

  ingress {
    description = "EFS mount target"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_efs_file_system" "ecs-efs" {
  encrypted = true
  #kms_key_id = "arn_of_custom_key"

  tags = {
    Name = "image-builder-jenkins"
  }
}

resource "aws_efs_backup_policy" "efs-policy" {
  file_system_id = aws_efs_file_system.jenkins-controller.id

  backup_policy {
    status = "ENABLED"
  }
}

resource "aws_efs_mount_target" "jenkins-controller" {
  for_each        = data.aws_subnet_ids.service.ids
  file_system_id  = aws_efs_file_system.jenkins-controller.id
  subnet_id       = each.value
  security_groups = [aws_security_group.jenkins-controller.id]
}

resource "aws_efs_access_point" "jenkins-home" {
  file_system_id = aws_efs_file_system.jenkins-controller.id
  root_directory {
    # path = "/var/jenkins_home"
    path = "/var/lib/jenkins"
  }
}

resource "aws_efs_access_point" "jenkins-workspace" {
  file_system_id = aws_efs_file_system.jenkins-controller.id
  root_directory {
    path = "/data/workspace"
  }
}