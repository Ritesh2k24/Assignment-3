# AWS Configuration Variables
AMI_ID="ami-12345678"  # Replace with a valid AMI ID
INSTANCE_TYPE="t2.micro"
KEY_NAME="MyKeyPair"  # Ensure you have MyKeyPair.pem locally
SECURITY_GROUP="my-security-group"

echo "Starting EC2 instance..."
AWS_INSTANCE_ID=$(aws ec2 run-instances \
    --image-id $AMI_ID \
    --count 1 \
    --instance-type $INSTANCE_TYPE \
    --key-name $KEY_NAME \
    --security-groups $SECURITY_GROUP \
    --query 'Instances[0].InstanceId' --output text)

echo "Instance $AWS_INSTANCE_ID is launching..."

# Wait for instance to be in a running state
echo "Waiting for instance to start..."
aws ec2 wait instance-running --instance-ids $AWS_INSTANCE_ID

# Get Public DNS Name of the instance
INSTANCE_DNS=$(aws ec2 describe-instances \
    --instance-ids $AWS_INSTANCE_ID \
    --query 'Reservations[0].Instances[0].PublicDnsName' \
    --output text)

echo "Instance is now running. Public DNS: $INSTANCE_DNS"

# Wait for SSH to be ready
echo "Waiting for SSH to be available..."
sleep 20  # Give the instance some time to boot

# Copy Flask application to EC2 instance
echo "Deploying Flask application..."
scp -i "$KEY_NAME.pem" app.py ubuntu@$INSTANCE_DNS:/home/ubuntu/

# SSH into EC2 and set up the environment
echo "Setting up and running the Flask app on EC2..."
ssh -i "$KEY_NAME.pem" ubuntu@$INSTANCE_DNS << EOF
sudo apt update
sudo apt install -y python3-pip
pip3 install flask
nohup python3 /home/ubuntu/app.py > /dev/null 2>&1 &
EOF

echo "Flask app deployed and running on EC2 at http://$INSTANCE_DNS:5000"

