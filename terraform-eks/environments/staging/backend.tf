terraform {
  backend "s3" {
    bucket          = "notesapi-raani-tfstate-2026"
    key             = "staging/terraform.tfstate"
    region          = "ap-south-1"
    dynamodb_table  = "notesapi-tf-locks"
    encrypt         = true
  }
}
