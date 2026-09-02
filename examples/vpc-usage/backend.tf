terraform {
  backend "s3" {
    bucket = "ralso11-terraform-state-2026"
    key    = "terraform-modules/vpc-usage/terraform.tfstate"
    region = "eu-central-1"
  }
}
