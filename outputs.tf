# ECS ========================
# for taskdef.json
output "ecs_app_task_execution_role_arn" {
  value = module.ecs.ecs_app_task_execution_role_arn
}

output "ecs_app_task_role_arn" {
  value = module.ecs.ecs_app_task_role_arn
}

output "app_container_name" {
  value = module.ecs.app_container_name
}

output "ecs_app_task_definition_family_name" {
  value = module.ecs.ecs_app_task_definition_family_name
}

# RDS ========================
output "rds_cluster_endpoint" {
  value = module.db.rds_cluster_endpoint
}

output "rds_cluster_reader_endpoint" {
  value = module.db.rds_cluster_reader_endpoint
}

output "rds_cluster_instance_endpoint" {
  value = module.db.rds_cluster_instance_endpoint
}