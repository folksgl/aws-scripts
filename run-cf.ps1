# Author: Garrett Folks
#
# This script automates the testing process for cloudformation scripts. I often find myself encountering 
# errors from cloudformation and having to debug, and this script makes the process a little easier.
# Please feel free to use and modify this script as necessary.

# Set reusable variables.
# This script assumes your template file is named <stack-name>.<template-format>

$stackName="your-stack"                             # Name of the cloudformation stack to create.
$bucketName="your-bucket"                           # Name of the s3 bucket where the template body is located.
$templateFormat="json"                              # File format of the template (json or yaml)
$parameters="--parameters file://your-params.json"  # File containing the parameters for your script.
$capabilities="--capabilities your-capabilities"    # The capabilities required for stack creation.
$rollbackPolicy="--disable-rollback"                # The rollback policy to use. Disabling causes longer stack deletion times.
$s3Prefix="https://s3.amazonaws.com"                # The s3 endpoint for the deployment region.
$templateURL="--template-url $s3Prefix/$bucketName/$stackName.$templateFormat"

# Make sure the s3 bucket has an up-to-date copy of the CF template.
aws s3 cp ./$stackName.json s3://$bucketName/ --quiet
Write-Output "Using most recent $stackName.$templateFormat file."

# If the previous stack is still there, delete it before we continue.
$stackExists=aws cloudformation list-stacks --query 'StackSummaries[?StackName==`'$stackName'`] | [?StackStatus!=`DELETE_COMPLETE`]' --output text
if ([string]::IsNullOrEmpty($stackExists)) {
    Write-Output "Deleting previous stack. Please wait..."
    aws cloudformation delete-stack --stack-name $stackName
    aws cloudformation wait stack-delete-complete --stack-name $stackName
}
else {
    Write-Output "No previous stack found. Deletion not needed."
}

# Create the new stack and let the user know.
Write-Output "Creating the new stack..."

# ***This line may require modification depending on your specific stack.***
aws cloudformation create-stack $rollbackPolicy --stack-name $stackName $templateURL --parameters $parameters $capabilities
aws cloudformation wait create-stack-complete --stack-name $stackName

