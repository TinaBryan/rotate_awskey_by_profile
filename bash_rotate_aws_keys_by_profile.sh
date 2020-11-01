#!/bin/bash


echo "SCRIPT TO ROTATE AWS ACCESS KEYS BY PROFILE"
echo "   " 
if [ "$#" -eq 0 ] || [ "$1" == "help" ] ;
then
echo "   "
echo "You can use arguments in the future ex: "
echo "     $0 $(whoami) default y"
echo "   "
echo "  Arguments, in order: username profilename yn"
echo "      username (your aws username)"
echo "      profilename (your local .aws/credentials profile you are changing)"
echo "      y or n (Auto Delete the old Key if desired)"
echo "   "
echo "leaving any or all arguments blank, will prompt you for those options"
echo "   "
fi

# GETTING USER LOGIN INFO
if [ "$1" ]; then
AWS_USER_NAME=$1
else
read -p "Enter your aws username: " username
AWS_USER_NAME=$username
echo $AWS_USER_NAME
if [ $AWS_USER_NAME == ""]
  then echo "You must enter username.. try again" && exit
fi
fi
if [ "$2" ]; 
then
user_profile="$2"
else
PROFILE_NAME=$(cat ~/.aws/credentials | grep -o '\[[^]]*\]')
echo "list of current profiles."
echo $PROFILE_NAME + "\n"
# input the profile name of the credentials you are rotating
read -p "please enter the .aws/credentials profile name to update or hit enter for default user: " user_profile
# catch they entered nothing
if [ $user_profile == ""]
  then user_profile="default"
fi
fi
echo $user_profile
echo "Getting the old Access Key ID for: $AWS_USER_NAME"
# echo $AWS_USER_NAME
#echo "old access key"
OLD_ACCESS_KEY=$(aws iam list-access-keys --user-name "$AWS_USER_NAME" --output text | cut -f2)
#echo $OLD_ACCESS_KEY
if [ $(aws iam list-access-keys --user-name "$AWS_USER_NAME" --output text|wc -l) -gt 1 ]
then
echo "****************************************************************************"
echo "****************************************************************************"
echo "You already have two keys.. you need to go into the console and delete any inactive or unused keys, so only your current key remains."
echo "****************************************************************************"
echo "They currently are: $OLD_ACCESS_KEY"
echo "****************************************************************************"
echo "Then you can re-run this script"
echo "****************************************************************************"
echo "****************************************************************************"
exit
fi
#creating new variable hoping to capture the old key only for delete
delete_old_access_key=$OLD_ACCESS_KEY
# create new access key and print output key value and secret value
#echo "Creating the new access key"
# NEW_ACCESS_KEY_RAW=$(aws iam create-access-key --user-name --output text "$AWS_USER_NAME" | cut -f2 -f4)
NEW=$(aws iam create-access-key --user-name "$AWS_USER_NAME" --output text)
# separate output to get new access key value
secret_key=$(echo $NEW | cut -f4 -d" ")
NEW_KEY=$(echo $NEW|cut -f2 -d" ")
echo "Created new key: $NEW_KEY"
# update credentials with aws configure
# updating access key value
echo "Updating local configuration for $AWS_USER_NAME with new  key"
## These are the env vars used for aws configure
AWS_ACCESS_KEY_ID="$NEW_KEY"
AWS_SECRET_ACCESS_KEY="$secret_key"
## run the aws configure script
##          aws configure --profile "$user_profile"
aws configure set aws_access_key_id "$AWS_ACCESS_KEY_ID" --profile "$user_profile"
aws configure set aws_secret_access_key "$AWS_SECRET_ACCESS_KEY" --profile "$user_profile"
# Has to sleep allowing aws to register the update otherwise the next step errors out.
echo "Sleep for 10 seconds while aws updates changes"
sleep 10
echo "Setting the old Access Key to Inactive"
$(aws iam update-access-key --access-key-id "$delete_old_access_key" --status Inactive --user-name "$AWS_USER_NAME")
# prep to delete old access key
inactive_access_key=$(aws iam list-access-keys --user-name "$AWS_USER_NAME" --output text | cut -f2)
if [ "$3" == "y" ]
then
$(aws iam delete-access-key --access-key "$delete_old_access_key" --user-name "$AWS_USER_NAME")
else
if [ "$3" == "n" ] 
then
echo "auto-deletion skipped"
else
while true; do
  read -p "Do you wish to delete the old inactive key $inactive_access_key (y|n)? " yn
  case $yn in
    [Yy]* ) echo "Deleting Access Key ID $inactive_access_key" | $(aws iam delete-access-key --access-key "$delete_old_access_key" --user-name "$AWS_USER_NAME"); break;;
    [Nn]* ) echo "Please delete this manually when ready";; 
    * ) echo "Please answer yes or no";;
  esac
done
fi
fi
echo "list current keys"
aws iam list-access-keys --user-name "$AWS_USER_NAME"
echo Done
