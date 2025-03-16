#!/bin/bash

# Threshold for CPU usage
THRESHOLD=75

while true; do
    # Get current CPU usage
    CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}' | cut -d. -f1)

    echo "Current CPU Usage: $CPU_USAGE%"

    if [ "$CPU_USAGE" -ge "$THRESHOLD" ]; then
        echo "CPU usage exceeded $THRESHOLD%, triggering migration..."
        bash migrate_to_aws.sh
        break
    fi

    sleep 5  # Check every 5 seconds
done
