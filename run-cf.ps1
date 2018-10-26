# Author: Garrett Folks
#
# This script automates the testing process for cloudformation scripts. I often find myself encountering 
# errors from cloudformation and having to debug, and this script makes the process a little easier.
# Please feel free to use and modify this script as necessary.

# Set reusable variables.
# This script assumes your template file is named <stack-name>.<template-format>

$stackName="your-stack"                          # Name of the stack to create.
$bucketName="your-bucket"                        # Name of the bucket where the template body is located.
$templateFormat="json"                           # Format the template is in (json or yaml)
$paramFile="file://your-params.json"             # File containint the parameters for your script.
$capabilities="--capabilities your-capabilities" # The capabilities required for stack creation.

# Make sure the s3 bucket has an up-to-date copy of the CF template
aws s3 cp ./$stackName.json s3://$bucketName/ --quiet
echo "Using most recent $stackName.$templateFormat file."

# If the previous stack is still there, delete it before we continue.
$stackExists=aws cloudformation list-stacks --query 'StackSummaries[?StackName==`$stackName`] | [?StackStatus!=`DELETE_COMPLETE`]' --output text
if ($stackExists) {
    echo "Deleting previous stack. Please wait..."
    aws cloudformation delete-stack --stack-name $stackName
    aws cloudformation wait stack-delete-complete --stack-name $stackName
}
else {
    echo "No previous stack found. Deletion not needed."
}

# Create the new stack and let the user know.
echo "Creating the new stack..."

# ***This line may require modification depending on your specific stack.***
aws cloudformation create-stack --stack-name $stackName --template-url https://s3.amazonaws.com/$bucketName/$stackName.$templateFormat --parameters $paramsFile $capabilities
