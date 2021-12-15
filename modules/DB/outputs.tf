output "rds_cluster_endpoint" {
  value = aws_rds_cluster.rds_cluster.endpoint
}

output "rds_cluster_reader_endpoint" {
  value = aws_rds_cluster.rds_cluster.reader_endpoint
}

output "rds_cluster_instance_endpoint" {
  value = aws_rds_cluster_instance.rds_cluster_instance.endpoint
}

output "rds_master_username" {
  value = aws_rds_cluster.rds_cluster.master_username
}

output "rds_master_password" {
  value = aws_rds_cluster.rds_cluster.master_password
}

output "rds_database_name" {
  value = aws_rds_cluster.rds_cluster.database_name
}

output "postgres_rds_url" {
  # Reader pattern
  #  value = "postgres://${aws_rds_cluster.rds_cluster.master_username}:${aws_rds_cluster.rds_cluster.master_password}@${aws_rds_cluster.rds_cluster.endpoint},${aws_rds_cluster.rds_cluster.reader_endpoint}/${aws_rds_cluster.rds_cluster.database_name}"
  # No Reader pattern
  value = format(
    "postgres://%s:%s@%s:%s/%s",
    aws_rds_cluster.rds_cluster.master_username,
    aws_rds_cluster.rds_cluster.master_password,
    aws_rds_cluster.rds_cluster.endpoint,
    "5432",
    aws_rds_cluster.rds_cluster.database_name
  )
}