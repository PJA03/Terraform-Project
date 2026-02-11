# Fixed name so you don't have to edit backend.tf every day
$bucketName = "galias-finalproject-statefile"
$region = "ap-southeast-1"

Write-Host "Checking if bucket $bucketName exists..."

# Try to create the bucket. If it exists, catch the error and continue.
try {
    aws s3api create-bucket --bucket $bucketName --region $region --create-bucket-configuration LocationConstraint=$region 2>$null
    Write-Host "Bucket created successfully."
}
catch {
    Write-Host "Bucket already exists or could not be created. (This is fine if you didn't delete it yesterday)"
}

# enable versioning
aws s3api put-bucket-versioning --bucket $bucketName --versioning-configuration Status=Enabled

Write-Host "------------------------------------------------"
Write-Host "Backend is ready!"
Write-Host "Ensure your backend.tf says: bucket = '$bucketName'"
Write-Host "------------------------------------------------"