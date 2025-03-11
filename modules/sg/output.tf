# output "webserver_sg_id" {
#     value = aws_security_group.webserver_sg.id
  
# }

output "security_group_ids" {
  value = [for sg in aws_security_group.sg : sg.id]
}