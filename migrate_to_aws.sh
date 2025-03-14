#!/bin/bash

AWS_INSTANCE_TYPE="t2.micro"
AWS_AMI_ID="ami-12345678"
AWS_KEY_NAME="MyKeyPair"
AWS_SECURITY_GROUP="my-security-group"

# Launch EC2 instance
INSTANCE_ID=$(aws ec2 run-instances \
    --image-id $AWS_AMI_ID \
    --instance-type $AWS_INSTANCE_TYPE \
    --key-name $AWS_KEY_NAME \
    --security-groups $AWS_SECURITY_GROUP \
    --query 'Instances[0].InstanceId' --output text)

# Wait for instance to be ready
aws ec2 wait instance-running --instance-ids $INSTANCE_ID

# Get instance public DNS
INSTANCE_DNS=$(aws ec2 describe-instances \
    --instance-ids $INSTANCE_ID \
    --query 'Reservations[0].Instances[0].PublicDnsName' --output text)

# Deploy the application
scp -i "$AWS_KEY_NAME.pem" app.py ubuntu@$INSTANCE_DNS:/home/ubuntu/
ssh -i "$AWS_KEY_NAME.pem" ubuntu@$INSTANCE_DNS << EOF
sudo apt update
sudo apt install -y python3-pip
pip3 install flask
nohup python3 /home/ubuntu/app.py > /dev/null 2>&1 &
EOF

echo "App migrated to EC2 at http://$INSTANCE_DNS:5000"
