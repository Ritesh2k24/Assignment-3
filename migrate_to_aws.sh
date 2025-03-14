#!/bin/bash

AWS_INSTANCE_ID=$(aws ec2 run-instances \
    --image-id ami-12345678 \
    --count 1 \
    --instance-type t2.micro \
    --key-name MyKeyPair \
    --security-groups my-security-group \
    --query 'Instances[0].InstanceId' --output text)

echo "Instance $AWS_INSTANCE_ID created."

# Deploy the application to the new EC2 instance
scp -i MyKeyPair.pem app.py ubuntu@$(aws ec2 describe-instances \
    --instance-ids $AWS_INSTANCE_ID \
    --query 'Reservations[0].Instances[0].PublicDnsName' \
    --output text):/home/ubuntu/

ssh -i MyKeyPair.pem ubuntu@$(aws ec2 describe-instances \
    --instance-ids $AWS_INSTANCE_ID \
    --query 'Reservations[0].Instances[0].PublicDnsName' \
    --output text) << EOF
sudo apt update
sudo apt install -y python3-pip
pip3 install flask
nohup python3 /home/ubuntu/app.py &
EOF
