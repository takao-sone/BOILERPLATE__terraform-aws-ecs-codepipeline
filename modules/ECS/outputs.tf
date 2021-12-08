output "ecs_cluster_name" {
  value = aws_ecs_cluster.cluster.name
}

output "app_ecs_service_name" {
  value = aws_ecs_service.app.name
}

output "app_container_security_group_id" {
  value = aws_security_group.container.id
}

output "ecs_app_task_execution_role_arn" {
  value = aws_iam_role.ecs_app_task_execution_role.arn
}

output "ecs_app_task_role_arn" {
  value = aws_iam_role.ecs_app_task_role.arn
}

output "app_container_name" {
  value = var.app_container_name
}

output "ecs_app_task_definition_family_name" {
  value = aws_ecs_task_definition.app.family
}
