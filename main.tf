module "website" {
  source      = "./modules/website"
  bucket_name = "mytechynurse-static-website-bucket"  
}

terraform {
  backend "s3" {
    bucket         = "mytechynurse-static-website-bucket"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
