# CodeDeploy 애플리케이션 생성
resource "aws_codedeploy_app" "istory-app" {
  name = "istory-app"
}

resource "aws_codedeploy_deployment_group" "istory_prod_deploy_group" {
  app_name               = aws_codedeploy_app.istory-app.name
  deployment_group_name  = "istory-prod-deploy-group"
  service_role_arn      = aws_iam_role.codedeploy_service_role.arn

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "IN_PLACE"
  }

  load_balancer_info {
    target_group_info {
      name = aws_lb_target_group.istory_tg.name
    }
  }

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  ec2_tag_set {
    ec2_tag_filter {
      key   = "Environment"
      type  = "KEY_AND_VALUE"
      value = "Production"
    }
  }

  trigger_configuration {
    trigger_events = ["DeploymentSuccess", "DeploymentFailure"]
    trigger_name   = "prod-deployment-trigger"
    trigger_target_arn = aws_sns_topic.deployment_notifications.arn
  }

  alarm_configuration {
    enabled = true
    alarms  = ["istory-prod-deployment-alarm"]
  }
}

# CodeDeploy 애플리케이션 이름 출력
output "codedeploy_app_name" {
  value       = aws_codedeploy_app.istory-app.name
  description = "Name of the CodeDeploy application"
}

# CodeDeploy 배포 그룹 이름 출력
output "codedeploy_deployment_group_name" {
  value       = aws_codedeploy_deployment_group.istory_prod_deploy_group.deployment_group_name
  description = "Name of the CodeDeploy deployment group"
} 

# SNS 토픽 생성
resource "aws_sns_topic" "deployment_notifications" {
  name = "istory-deployment-notifications"
}

output "prod_alb_dns" {
  value       = aws_lb.istory_alb.dns_name
  description = "The DNS name of the production ALB"
}

output "prod_deployment_group_name" {
  value       = aws_codedeploy_deployment_group.istory_prod_deploy_group.deployment_group_name
  description = "Name of the production CodeDeploy deployment group"
}