#!/bin/bash
set -ex 
exec > /var/log/user-data.log 2>&1
apt-get update -y && apt-get upgrade -y
apt-get install -y curl unzip jq
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
INSTANCE_ID=$(ec2metadata --instance-id)
RUNNER_NAME="runner-${INSTANCE_ID}"
ACTION_RUNNER_VERSION=2.311.0
GITHUB_OWNER=$(aws ssm get-parameter --name "/lambda/github-owner" --with-decryption --query "Parameter.Value" --output text --region us-west-1)
PAT=$(aws ssm get-parameter --name "/lambda/github-token" --with-decryption --query "Parameter.Value" --output text --region us-west-1)

cd /home/ubuntu

mkdir -p actions-runner && cd actions-runner


curl -o actions-runner-linux-x64-${ACTION_RUNNER_VERSION}.tar.gz -L \
  https://github.com/actions/runner/releases/download/v${ACTION_RUNNER_VERSION}/actions-runner-linux-x64-${ACTION_RUNNER_VERSION}.tar.gz


tar xzf actions-runner-linux-x64-${ACTION_RUNNER_VERSION}.tar.gz
chown -R ubuntu:ubuntu /home/ubuntu/actions-runner
chmod +x /home/ubuntu/actions-runner/*.sh

TOKEN=$(curl -s -L -X POST \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $PAT" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/repos/$GITHUB_OWNER/test/actions/runners/registration-token | jq -r '.token')

sudo -u ubuntu /home/ubuntu/actions-runner/config.sh --url https://github.com/$GITHUB_OWNER/test --token $TOKEN --name $RUNNER_NAME --labels self-hosted-runner --unattended --replace

cd /home/ubuntu/actions-runner
sudo ./svc.sh install
sudo ./svc.sh start
# aws ec2 create-tags --resources "$INSTANCE_ID" --tags Key=RunnerLabel,Value="self-hosted-runner"


cat <<'EOF' > /home/ubuntu/self_stop.sh
#!/bin/bash

# Get instance ID
INSTANCE_ID=$(ec2metadata --instance-id)

# Define paths
RUNNER_DIR="/home/ubuntu/actions-runner"
TIMESTAMP_FILE="/home/ubuntu/last_job_time.txt"
LOG_FILE="/home/ubuntu/actions-runner/_diag/Runner_*.log"

# Ensure timestamp file exists
if [[ ! -f $TIMESTAMP_FILE ]]; then
    echo "0" | sudo tee $TIMESTAMP_FILE > /dev/null
    sudo chown ubuntu:ubuntu $TIMESTAMP_FILE
    sudo chmod 644 $TIMESTAMP_FILE
fi

# Extract last job completion timestamp (FIXED)
LAST_JOB_TIMESTAMP=$(sudo grep -i "JobCompleted" $LOG_FILE | tail -1 | awk '{print $2}')

# Ensure timestamp is valid before proceeding
if [[ -n $LAST_JOB_TIMESTAMP ]]; then
    JOB_UNIX_TIME=$(date -d $LAST_JOB_TIMESTAMP +%s 2>/dev/null)

    if [[ $? -eq 0 && $JOB_UNIX_TIME -gt 0 ]]; then
        echo $JOB_UNIX_TIME | sudo tee $TIMESTAMP_FILE > /dev/null
    else
        echo " Error: Invalid timestamp format:" $LAST_JOB_TIMESTAMP
        exit 1
    fi
else
    echo "No job completion entry found in logs."
fi

# Read the last stored job time
LAST_JOB_TIME=$(cat $TIMESTAMP_FILE)

# Ensure the last job time is a valid number
if ! [[ $LAST_JOB_TIME =~ ^[0-9]+$ ]]; then
    echo " Error: Invalid timestamp stored in $TIMESTAMP_FILE"
    exit 1
fi

CURRENT_TIME=$(date +%s)
TIME_DIFF=$((CURRENT_TIME - LAST_JOB_TIME))

echo " Current Time: $CURRENT_TIME"
echo " Last Job Time: $LAST_JOB_TIME"
echo " Time Difference: $TIME_DIFF seconds"

# Stop instance if no job has run in the last 15 minutes (900 seconds)
if [[ $LAST_JOB_TIME -eq 0 || $TIME_DIFF -ge 900 ]]; then
    echo " No job has run in the last 15 minutes. Stopping instance: $INSTANCE_ID"
    
    # Ensure AWS CLI works
    if aws ec2 stop-instances --instance-ids $INSTANCE_ID; then
        echo "instance stopped."
    else
        echo " Error: Failed to stop instance. Check AWS permissions."
    fi
else
    REMAINING_TIME=$((900 - TIME_DIFF))
    echo " Job ran recently. Waiting. Remaining time: $REMAINING_TIME seconds."
fi
EOF
sudo chown ubuntu:ubuntu /home/ubuntu/self_stop.sh
chmod +x /home/ubuntu/self_stop.sh
echo "*/10 * * * * /bin/bash /home/ubuntu/self_stop.sh >> /home/ubuntu/cron.log 2>&1" | sudo -u ubuntu crontab -

