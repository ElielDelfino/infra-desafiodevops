#state.tf
terraform { 
    backend "s3" {
      bucket = "terraform-state-guinho"
      key = "lab/terraform.tfstate"
      region = "us-east-2"
      encrypt = true
    }
}

# #terraform {
#   backend "s3" {
#     bucket         = "seu-bucket-tfstate-prod"
#     key            = "state/terraform.tfstate"
#     region         = "us-east-1"
#     encrypt        = true
#     dynamodb_table = "tfstate-lock-prod"
#   }
# }

# # Crie DynamoDB table para lock
# aws dynamodb create-table \
#     --table-name tfstate-lock-prod \
#     --attribute-definitions AttributeName=LockID,AttributeType=S \
#     --key-schema AttributeName=LockID,KeyType=HASH \
#     --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
#     --region us-east-1

# # Crie bucket S3 versionado
# aws s3api create-bucket --bucket seu-bucket-tfstate-prod --region us-east-1
# aws s3api put-bucket-versioning --bucket seu-bucket-tfstate-prod --versioning-configuration Status=Enabled