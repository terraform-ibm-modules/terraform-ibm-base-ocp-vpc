resource "terraform_data" "jq_example" {
  provisioner "local-exec" {
    command = <<EOT
echo '{"name":"alice","age":30}' | jq -r '.name'
EOT
  }
}