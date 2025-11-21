output "vpc_id" {
  value = aws_vpc.redis_vpc.id
}

output "bastion_public_ip" {
  value = aws_instance.bastion.public_ip
}

output "redis_master_private_ip" {
  value = aws_instance.redis_master.private_ip
}

output "redis_replica_private_ip" {
  value = aws_instance.redis_replica.private_ip
}

output "private_key_path" {
  description = "Local path of generated PEM key"
  value       = local_file.redis_private_key.filename
}

output "s3_bucket_name" {
  value = aws_s3_bucket.redis_bucket.id
}
