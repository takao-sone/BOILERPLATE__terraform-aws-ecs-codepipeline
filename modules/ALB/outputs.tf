output "alb_security_group_id" {
  value = aws_security_group.alb_sg.id
}

output "app_service_blue_target_group_arn" {
  value = aws_alb_target_group.alb_blue_tg.arn
}

output "app_service_green_target_group_arn" {
  value = aws_alb_target_group.alb_green_tg.arn
}

output "alb_blue_target_group_name" {
  value = aws_alb_target_group.alb_blue_tg.name
}

output "alb_green_target_group_name" {
  value = aws_alb_target_group.alb_green_tg.name
}

output "alb_http_listener_arn" {
  value = aws_alb_listener.alb_http_listener.arn
}

output "alb_http_test_listener_arn" {
  value = aws_alb_listener.alb_http_test_listener.arn
}
