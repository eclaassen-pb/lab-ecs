resource "aws_security_group" "ecs_ec2_sg" {
  name        = "${var.asg_naming_prefix}-ec2-sg"
  vpc_id      = var.asg_vpc_id

  ingress {
    description      = "SSH ingress"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = var.ecs_ingress_cidrs
  }
  
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ecs_asg_sg" {
  name        = "${var.asg_naming_prefix}-asg-sg"
  vpc_id      = var.asg_vpc_id

  ingress {
    description      = "HTTP ingress"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = var.ecs_ingress_cidrs
  }
  
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
}

resource "aws_launch_configuration" "ecs_launch_config" {
  image_id             = var.ecs_ec2_ami
  iam_instance_profile = aws_iam_instance_profile.ecs-role.name
  security_groups      = [aws_security_group.ecs-ec2-sg.id]
  user_data = templatefile("${path.module}/user_data.sh", 
    ecs_cluster                 = aws_ecs_cluster.this.name
    log_group                   = aws_cloudwatch_log_group.instance.name
    efs_id                      = var.efs-id
    efs_jenkins_home_ap_id      = var.efs-jenkins-home-ap-id
    efs_workspace_data_ap_id    = var.efs-workspace-data-ap-id
  })
  instance_type        = "t2.micro"
  key_name             = var.ecs_ec2_key_name
}

resource "aws_autoscaling_group" "ecs_asg" {
  name                      = "ecs-asg"
  vpc_zone_identifier       = var.asg_subnet_ids
  launch_configuration      = aws_launch_configuration.ecs_launch_config.name
  desired_capacity          = var.asg_desired_capacity_asg
  min_size                  = var.asg_min_size_asg
  max_size                  = var.asg_max_size_asg
  health_check_grace_period = 150
  health_check_type         = "EC2"
}