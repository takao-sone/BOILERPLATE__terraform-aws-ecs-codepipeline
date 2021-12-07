output "ecs_cluster_name" {
  value = aws_ecs_cluster.cluster.name
}

output "app_ecs_service_name" {
  value = aws_ecs_service.app.name
}

output "app_container_security_group_id" {
  value = aws_security_group.container.id
}
