terraform {
  backend "s3" {
    # bucket name where state files will be stored
    bucket = "galias-terraform-state"

    # statefile path  (inside capstone module)
    key = "capstone/terraform.tfstate"

    region       = "ap-southeast-1"
    use_lockfile = true #native s3 locking
    encrypt      = true
  }
}