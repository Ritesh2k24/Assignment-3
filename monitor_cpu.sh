#!/bin/bash

# CPU Usage Thresholds
THRESHOLD_UP=75
THRESHOLD_DOWN=75
INSTANCE_ID_FILE="instance_id.txt"

while true; do
    # Get Current CPU Usage
    CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}' | cut -d. -f1)

    echo "Current CPU Usage: $CPU_USAGE%"

    if (( CPU_USAGE >= THRESHOLD_UP )); then
        echo "CPU usage exceeded $THRESHOLD_UP%, triggering migration..."
        
        bash migrate_to_aws.sh  # This should launch the EC2 instance and migrate the app
        
        # Store instance ID for later termination
        INSTANCE_ID=$(aws ec2 describe-instances --filters "Name=instance-state-name,Values=running" \
            --query "Reservations[*].Instances[*].InstanceId" --output text)
        
        echo "$INSTANCE_ID" > $INSTANCE_ID_FILE
        echo "EC2 Instance Started: $INSTANCE_ID"

    elif (( CPU_USAGE < THRESHOLD_DOWN )) && [ -f "$INSTANCE_ID_FILE" ]; then
        echo "CPU usage dropped below $THRESHOLD_DOWN%, terminating EC2 instance..."
        
        INSTANCE_ID=$(cat $INSTANCE_ID_FILE)
        aws ec2 terminate-instances --instance-ids $INSTANCE_ID
        
        rm $INSTANCE_ID_FILE  # Clean up stored instance ID
    fi

    sleep 5  # Check every 5 seconds
done
