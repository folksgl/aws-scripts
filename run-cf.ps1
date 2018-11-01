# Author: Garrett Folks
#
# This script automates the testing process for cloudformation scripts. I often find myself encountering 
# errors from cloudformation and having to debug, and this script makes the process a little easier.
# Please feel free to use and modify this script as necessary.

# Set reusable variables.
# This script assumes your template file is named <stack-name>.<template-format>

$stackName="your-stack"                             # Name of the cloudformation stack to create.
$stackTemplateFile="teamcity-setup.json"            # File containing the CF template
$bucketName="your-bucket"                           # Name of the s3 bucket where the template body is located.
$parameters="--parameters file://your-params.json"  # File containing the parameters for your script.
$capabilities="--capabilities your-capabilities"    # The capabilities required for stack creation.
$rollbackPolicy="--disable-rollback"                # The rollback policy to use. Disabling causes longer stack deletion times.
$s3Prefix="https://s3.amazonaws.com"                # The s3 endpoint for the deployment region.
$nestedStackNames=@("nested-stack.json", "stack2.json") # The names of any nested stacks used in the main stack.
$nestedStackBuckets=@("nested-stack-bucket", "bucket2") # Location of the nested stacks.

# Make sure the s3 bucket has an up-to-date copy of the CF template.
aws s3 cp ./$stackTemplateFile s3://$bucketName/ --quiet
Write-Output "Using most recent $stackTemplateFile file."

# Make sure nested stacks are up-to-date as well.
for ($i=0; $i -lt $nestedStackNames.length; $i++) {
    aws s3 cp $nestedStackNames[$i] s3://$nestedStackBuckets/ --quiet
    Write-Output "Using most recent $nestedStackNames[$i] file."
}

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

# Build the templateURL from supplied parameters to clean up call to stack-create.
$templateURL="--template-url $s3Prefix/$bucketName/$stackTemplateFile"

# ***This line may require modification depending on your specific stack.***
aws cloudformation create-stack $rollbackPolicy --stack-name $stackName $templateURL $parameters $capabilities
aws cloudformation wait create-stack-complete --stack-name $stackName

