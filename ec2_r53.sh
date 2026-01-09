#!/bin/bash

AMI_ID=ami-09c813fb71547fc4f
SECURITY_GROUP_ID=sg-09135f6961d4e1c54

LOG_FOLDER="/var/log/shell-roboshop"
LOG_FILE="$LOG_FOLDER/$0.log"

if [ ! -d LOG_FOLDER ]; then
    mkdir $LOG_FOLDER
fi

if [ ! -f LOG_FILE ]; then
    touch $LOG_FILE
fi

for ec2 in $@
do
    if [ $ec2 = "frontend" ]; then
        IP=$(aws ec2 run-instances --image-id $AMI_ID --instance-type t3.micro --security-group-ids $SECURITY_GROUP_ID --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$ec2}]" --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)

        RECORD_NAME="$ec2.bloombear.fun"
    else 
        IP=$(aws ec2 run-instances --image-id $AMI_ID --instance-type t3.micro --security-group-ids $SECURITY_GROUP_ID --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$ec2}]" --query 'Reservations[0].Instances[0].PrivateIpAddress' --output text)

        RECORD_NAME="$ec2.bloombear.fun"
    fi

    aws route53 change-resource-record-sets \
    --hosted-zone-id Z0948150OFPSYTNVYZOY \
    --change-batch '
    {
        "Comment": "Creating/Updating Record Set",
        "Changes": [{
            "Action"              : "UPSERT",
            "ResourceRecordSet"  : {
                "Name"              : "'$RECORD_NAME'",
                "Type"             : "A",
                "TTL"              : 1 ,
                "ResourceRecords"  : [{
                    "Value"         : "'${IP}'"
                }]
            }
        }]
    }'

done
