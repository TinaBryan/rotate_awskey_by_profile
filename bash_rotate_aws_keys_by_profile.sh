#!/bin/bash

#Enter your AWS User Name in the AWS_USER_NAME variable value prior to running script
# ADD AWS USER NAME HERE
read -p "please enter your aws username: " username
AWS_USER_NAME=$username
echo $AWS_USER_NAME

# input the profile name of the credentials you are rotating
read -p "please enter the .aws/credentials profile name to update or hit enter for default user: " user_profile
echo $user_profile


echo "Getting the old Access Key ID for: "
echo $AWS_USER_NAME

OLD_ACCESS_KEY=$(aws iam list-access-keys --user-name "$AWS_USER_NAME" --output text | cut -f2)
echo $OLD_ACCESS_KEY

# create new access key and print output key value and secret value
echo "Creating the new access key raw"

NEW_ACCESS_KEY_RAW=$(aws iam create-access-key --user-name --output text "$AWS_USER_NAME" | cut -f2 -f4)
echo $NEW_ACCESS_KEY_RAW

# separate output to get new access key value
new_access_key=($NEW_ACCESS_KEY_RAW)
clean_new_access_key="${new_access_key[0]}"
echo $clean_new_access_key

# separate output for new secret value
new_secret_key=($NEW_ACCESS_KEY_RAW)
clean_new_secret="${new_secret_key[1]}"
echo $clean_new_secret

# update credentials with aws configure
# updating access key value
echo "Setting the new configuration for access key"
$(aws configure set aws_access_key_id $clean_new_access_key --profile "$user_profile")

# # updating secret value
echo "setting configuration for new secret value"
$(aws configure set aws_secret_access_key $clean_new_secret --profile "$user_profile")


# Has to sleep allowing aws to register the update otherwise the next step errors out.
echo "sleep while aws updates changes"
sleep 7
echo "Setting the old Access Key to Inactive"
$(aws iam update-access-key --access-key-id "$OLD_ACCESS_KEY" --status Inactive --user-name "$AWS_USER_NAME")

# prep to delete old access key
inactive_access_key=$(aws iam list-access-keys --user-name "$AWS_USER_NAME" --output text | cut -f2)
while true; do
  read -p "Do you wish to delete the old inactive key $inactive_access_key (y|n)? " yn
  case $yn in
    [Yy]* ) echo "Deleting Access Key ID $inactive_access_key" | $(aws iam delete-access-key --access-key "$OLD_ACCESS_KEY" --user-name "$AWS_USER_NAME"); break;;
    [Nn]* ) echo "Please delete this manually when ready"; exit;;
    * ) echo "Please answer yes or no";;
  esac
done
echo "list user keys"
aws iam list-access-keys --user-name "$AWS_USER_NAME"