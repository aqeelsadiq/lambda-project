
output "instance_profile_names" {
  value = [for profile in aws_iam_instance_profile.ec2_profiles : profile.name]
}
