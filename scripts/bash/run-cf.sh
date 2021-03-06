#!/bin/bash
#
# Author: Garrett Folks
#
# This script automates the testing process for cloudformation scripts. I often find myself encountering 
# errors from cloudformation and having to debug, and this script makes the process a little easier.
# Please feel free to use and modify this script as necessary. If you add something cool, create a pull request!

# Set reusable variables.

stackName="your-stack"                             # Name of the cloudformation stack to create.
stackTemplateFile="your-template.type"             # File containing the CF template
bucketName="your-bucket"                           # Name of the s3 bucket where the template body is located.
parameters="--parameters=file://your-params.json"  # File containing the parameters for your script.
capabilities="--capabilities=your-capabilities"    # The capabilities required for stack creation.
rollbackPolicy="--disable-rollback"                # The rollback policy to use. Disabling causes longer stack deletion times.
s3Prefix="https://s3.amazonaws.com"                # The s3 endpoint for the deployment region.
nestedStackNames=("file1" "file2")                 # The names of any nested stacks used in the main stack.
nestedStackBuckets=("bucket1" "bucket2")           # Location of the nested stacks.

# Make sure the s3 bucket has an up-to-date copy of the CF template.
aws s3 cp ./$stackTemplateFile s3://$bucketName/ --quiet
echo "Using most recent $stackTemplateFile file."

# Make sure nested stacks are up-to-date as well.
for (( i=0; i<${#nestedStackNames[@]}; i++ ));
do
    aws s3 cp "${nestedStackNames[$i]}" s3://"${nestedStackBuckets[$i]}"/ --quiet
    echo "Using most recent ${nestedStackNames[$i]} file."
done

# Delete the old stack.
echo "Deleting previous stack. Please wait..."
aws cloudformation delete-stack --stack-name $stackName
aws cloudformation wait stack-delete-complete --stack-name $stackName

# Create the new stack.  
echo "Creating the new stack..."

# Build the templateURL from supplied parameters to clean up call to stack-create.
templateURL="--template-url $s3Prefix/$bucketName/$stackTemplateFile"

# ***This line may require modification depending on your specific stack.***
aws cloudformation create-stack $rollbackPolicy --stack-name $stackName "$templateURL" $parameters $capabilities
aws cloudformation wait create-stack-complete --stack-name $stackName

