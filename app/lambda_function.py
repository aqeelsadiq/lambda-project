import json
import boto3
import urllib.request
import os

# AWS EC2 client
ec2 = boto3.client("ec2", region_name="us-west-1")

# GitHub API details
GITHUB_TOKEN = os.environ["GITHUB_TOKEN"]
GITHUB_OWNER = os.environ["GITHUB_OWNER"]
REPO_NAME = os.environ["REPO_NAME"]

HEADERS = {
    "Authorization": f"token {GITHUB_TOKEN}",
    "Accept": "application/vnd.github.v3+json"
}

def get_queued_jobs():
    """Fetch running and queued jobs from GitHub Actions."""
    try:
        url = f"https://api.github.com/repos/{GITHUB_OWNER}/{REPO_NAME}/actions/runs"
        req = urllib.request.Request(url, headers=HEADERS)
        with urllib.request.urlopen(req) as response:
            data = json.loads(response.read().decode())

            queued_jobs = sum(1 for run in data.get("workflow_runs", []) if run.get("status") in ["queued", "waiting", "pending"])
            print(f"Jobs in queue: {queued_jobs}")
            return queued_jobs

    except Exception as e:
        print(f"GitHub API error: {e}")
        return 0  # Assume no jobs if API call fails

def get_instances():
    """Fetch stopped and running EC2 instances tagged as self-hosted runners."""
    try:
        response = ec2.describe_instances(Filters=[{"Name": "tag:RunnerLabel", "Values": ["self-hosted-runner"]}])
        stopped_instances, running_instances = [], []

        for reservation in response.get("Reservations", []):
            for instance in reservation.get("Instances", []):
                instance_id = instance["InstanceId"]
                state = instance["State"]["Name"]

                if state == "stopped":
                    stopped_instances.append(instance_id)
                elif state == "running":
                    running_instances.append(instance_id)

        print(f"Stopped instances: {stopped_instances}, Running instances: {running_instances}")
        return stopped_instances, running_instances

    except Exception as e:
        print(f"EC2 API error: {e}")
        return [], []  # Assume no instances if API call fails

def lambda_handler(event, context):
    """Lambda function to manage EC2 instances based on GitHub Actions job queue."""
    body = event.get("body", "{}")
    action = ""
    run_attempt = 0
    is_awaiting = False
    try:
        body = json.loads(body)
        action = body.get("action", "")
        workflow_run = body.get("workflow_run", { "run_attempt": None })
        run_attempt = workflow_run.get("run_attempt", 0)
        before = body.get("before", "")
        after = body.get("after", "")
        if before or after and (not action and not run_attempt > 1):
            is_awaiting = True
    except e as Exception:
        pass
    
    if action == "requested":
        print(f"Lambda event received: {json.dumps(event)}")
    elif action == "in_progress" and run_attempt > 1:
        print(f"Lambda event received (Re-run enqueued): {json.dumps(event)}")
    elif is_awaiting:
        print(f"Lambda event received but shall wait: {json.dumps(event)}")

    queued_jobs = get_queued_jobs()
    if queued_jobs == 0:
        print("No jobs in queue. Exiting.")
        return {"statusCode": 200, "body": json.dumps({"message": "No jobs in queue."})}

    stopped_instances, running_instances = get_instances()
    if len(running_instances) >= queued_jobs:
        print("Enough instances are already running.")
        return {"statusCode": 200, "body": json.dumps({"message": "No need to start new instances."})}

    instances_to_start = stopped_instances[:min(queued_jobs - len(running_instances), len(stopped_instances))]
    
    if instances_to_start:
        print(f"Starting instances: {instances_to_start}")
        try:
            ec2.start_instances(InstanceIds=instances_to_start)
            print(f"Successfully started: {instances_to_start}")
            return {"statusCode": 200, "body": json.dumps({"message": f"Started instances: {instances_to_start}"})}
        except Exception as e:
            print(f"Failed to start instances: {e}")

    print("No stopped instances available to start.")
    return {"statusCode": 200, "body": json.dumps({"message": "No available stopped instances."})}
