resource "aws_security_group" "efs" {
  name   = "${var.efs_naming_prefix}-efs-sg"
  vpc_id = var.efs_vpc_id

  ingress {
    description = "EFS mount target"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = ["10.101.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_efs_file_system" "efs" {
  encrypted = true
  #kms_key_id = "arn_of_custom_key"
}

resource "aws_efs_backup_policy" "efs_policy" {
  file_system_id = aws_efs_file_system.efs.id

  backup_policy {
    status = "DISABLED"
  }
}

resource "aws_efs_mount_target" "efs_mount_target" {
  for_each        = toset(var.efs_subnet_ids)
  file_system_id  = aws_efs_file_system.efs.id
  subnet_id       = each.value
  security_groups = [aws_security_group.efs.id]
}

resource "aws_efs_access_point" "jenkins_home" {
  file_system_id = aws_efs_file_system.efs.id
  root_directory {
    path = "/var/lib/jenkins"
  }
}

resource "aws_efs_access_point" "jenkins_workspace" {
  file_system_id = aws_efs_file_system.efs.id
  root_directory {
    path = "/data/workspace"
  }
}