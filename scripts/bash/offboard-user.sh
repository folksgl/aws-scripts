#!/bin/bash
#
# Author: Garrett Folks
#
# This script automates the process of removing a user and their associated access-related aws resources.
# The GUI automates this process but for those with CLI only access or the need for automation, this script
# does the same thing and follows the AWS guidelines found here: 
# https://docs.aws.amazon.com/IAM/latest/UserGuide/id_users_manage.html#id_users_deleting
#

# Ensure iam user provided.
if [ "$#" -ne 1 ]; then
    echo "You must specify an IAM user to delete."
    exit
fi

# Set reusable variables.
iamUser=$1    # User name of the IAM user to remove.




# Delete all access keys the user has.
echo "Deleting access keys..."

accessKeys=$(aws iam list-access-keys --user-name "$iamUser" --output text | awk '{print $2}')
for key in $accessKeys
do
    echo "    Deleting key: $key"
    aws iam delete-access-key --access-key-id "$key"
done




# Delete all signing certificates the user has.
echo "Deleting signing certificates..."

signingCert=$(aws iam list-signing-certificates --user-name "$iamUser" --output text | awk '{print $2}')
for cert in $signingCert
do
    echo "    Deleting cert: $cert"
    aws iam delete-signing-certificate --certificate-id "$cert"
done




# Delete the login profile (password)
echo "Deleting login profile..."
aws iam delete-login-profile --user-name "$iamUser" 2> /dev/null




# Deactivate MFA device
echo "Deactivating MFA device..."

mfaDevices=$(aws iam list-mfa-devices --user-name CA-garrett.folks --output text | awk '{print $3}')
for device in $mfaDevices
do
    echo "    Deactivating device: $device"
    aws iam deactivate-mfa-device --user-name "$iamUser" --serial-number "$device"
done




# Detach policies
echo "Detaching policies..."

attachedPolicies=$(aws iam list-attached-user-policies --user-name CA-garrett.folks --output text | awk '{print $2}')
for policy in $attachedPolicies
do
    echo "    Detaching policy: $policy"
    aws iam detach-user-policy --user-name "$iamUser" --policy-arn "$policy"
done




# Remove user from groups
echo "Removing user from groups..."

groups=$(aws iam list-groups-for-user --user-name CA-garrett.folks --output text | awk '{print $5}')
for group in $groups
do
    echo "    Removing from group: $group"
    aws iam remove-user-from-group --user-name "$iamUser" --group-name "$group"
done




# Delete IAM User
echo "Deleteing IAM user..."
aws iam delete-user --user-name "$iamUser"

echo "Done"

