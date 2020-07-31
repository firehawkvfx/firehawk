resource "aws_fsx_lustre_file_system" "fsx_storage" {
  import_path      = "s3://${aws_s3_bucket.example.bucket}"
  storage_capacity = 1200
  subnet_ids       = [aws_subnet.example.id]
}