data "aws_vpc" "selected" {
    default = true  
}

data "aws_subnet" "selected" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }

} 
data "aws_ami" "amazon-linux-2" {
  owners = ["amazon"]
  most_recent = true
  filter {
    name = "name"
    values = [ "amzn2-ami-kernel-5.10*" ]
  }
}  


resource "aws_launch_template" "asg-lt" {
    name = "phonebook-lt"
    image_id = "data.aws_ami.amazon-linux-2.id"
    instance_type = "t2.micro"
    key_name = "sky"
    vpc_security_group_ids = [ aws_security_group.server-sg.id ]
    user_data = filebase64("user_data.sh")
    depends_on = [github_repository_file.dbendpoint]
    tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "Web server of Phonebook App"
    }
  }


  
}

resource "aws_lb_target_group" "app-lb-tg" {
  name     = "phonebook-lb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.selected.id
  target_type = "instance"
  

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 3
  }



}

resource "aws_alb" "app-lb" {
  name = "phonebook-lb-tf"
  ip_address_type = "apv4"
  internal = false
  load_balancer_type = "application"
  securtity_groups = [aws_security_group.alb-sg.id]
  subnets = [data_aws_subnets.example.ids]
}

resource "aws_alb_listener" "name" {
    load_balancer_arn = aws_alb.app-lb.arn
    port = 80
    protocol = "HTTP"
    default_action {
      type = "forward"
      target_group_arn = aws_alb_target_group.app-lb-tg.arn

    }
}

resource "aws_autoscaling_group" "app-sg" {
    max_size = 3
    min_size = 1
    desired_capacity =  2
    name = "phonebook-asg"
    health_check_grace_period = 300
    health_check_type = "ELB"
    target_group_arns = [aws_alb_target_group.app-lb-tg.arn]
    vpc_zone_identifier = [ "aws_alb.app-lb.subnets" ]
    
    launch_template {
      id = aws_launch_template.asg-lt.id
      version = aws_launch_template.asg-lt.latest_version
    }

  
}

resource "aws_db_instance" "db-server" {
    instance_class = "db.t2.micro"
    allocated_storage = 20
    vpc_security_group_ids = [ "aws_security_group.db-sg.id" ]
    allow_major_version_upgrade = 
    auto_minor_version_upgrade = 0
    backup_retention_period = 0
    identifier = "phonebook-app-db"
    db-name = "phonebook"
    engine = "mysql"
    engine_version = "8.0.28"
    username = admin
    password = "12344321"
    monitoring_interval = 0
    multi_az = false
    port = 3306
    publicly_accessible = false
    skip_final_snapshot = true

    
}

resource "github_repository_file" "dbebdpoint" {
  content = aws_db_instance.db-server.adress
  file = "dbserver.endpoint"
  repository = "phonebook"
  overwrite_on_create = true
  branch = "master"


}
