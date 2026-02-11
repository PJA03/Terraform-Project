terraform {
  backend "s3" {
    # Replace this with the EXACT bucket name from your script output
    bucket = "galias-terraform-state"

    # The path to the state file inside the bucket
    key = "capstone/terraform.tfstate"

    region       = "ap-southeast-1"
    use_lockfile = true #native s3 locking
    encrypt      = true
  }
}