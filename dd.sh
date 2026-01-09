#!/bin/bash

AMI_ID="ami-09c813fb71547fc4f"
SECURITY_GROUP_ID="sg-03c4d065bf7f7f94d"
DOMAIN_NAME="bloombear.fun"

LOG_FOLDER="/var/log/shell-roboshop"
LOG_FILE="$LOG_FOLDER/$0.log"

set -euo pipefail

# Creating instances from the arguments passed to the script.
for instance in $@
do
    # Creating the EC2 instance and recording its instance ID in the INSTANCE_ID variable
    INSTANCE_ID=$(aws ec2 run-instances --image-id $AMI_ID --instance-type t3.micro --security-group-ids $SECURITY_GROUP_ID --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=${instance}}]" --query 'Instances[0].InstanceId' --output text) &>> LOG_FILE

    # Logic that retrieves the public IP for frontend instances and the private IP for backend instances.
    if [ $instance == "frontend" ]; then
        IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PublicIpAddress' --output text) &>> LOG_FILE
        RECORD_NAME="$DOMAIN_NAME"
    else 
        IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PrivateIpAddress' --output text) &>> LOG_FILE
        RECORD_NAME="$instance.$DOMAIN_NAME"
    fi

    # Updating the Route53 DNS records.
    aws route53 change-resource-record-sets \
  --hosted-zone-id Z01953923TROREUOJRMSG \
  --change-batch '
  {
    "Comment": "Updating record set"
    ,"Changes": [{
      "Action"              : "UPSERT"
      ,"ResourceRecordSet"  : {
        "Name"              : "'$RECORD_NAME'"
        ,"Type"             : "A"
        ,"TTL"              : 1
        ,"ResourceRecords"  : [{
            "Value"         : "'$IP'"
        }]
      }
    }]
  }
  '

done




