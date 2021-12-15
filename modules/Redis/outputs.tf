output "cache_node_address_primary_endpoint" {
  value = format(
    "%s:%s",
    aws_elasticache_cluster.redis_cluster.cache_nodes[0].address,
    aws_elasticache_cluster.redis_cluster.port
  )
}