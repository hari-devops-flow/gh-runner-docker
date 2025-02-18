#!/bin/bash

# # Debugging: Ensure variables are correctly passed
# echo "REPOSITORY: $REPO"
# echo "ACCESS_TOKEN: $TOKEN"

# Validate required variables
if [[ -z "$REPO" || -z "$TOKEN" ]]; then
    echo "Error: REPO or TOKEN is missing!"
    exit 1
fi

# Get GitHub Runner Registration Token
REG_TOKEN=$(curl -s -X POST -H "Authorization: token ${TOKEN}" \
    -H "Accept: application/vnd.github+json" \
    https://api.github.com/repos/${REPO}/actions/runners/registration-token | jq -r .token)

# Check if the token was received
if [[ -z "$REG_TOKEN" || "$REG_TOKEN" == "null" ]]; then
    echo "Error: Failed to fetch registration token. Check your GitHub PAT permissions."
    exit 1
fi

# Navigate to runner directory
cd /home/docker/actions-runner

# Register the GitHub runner
./config.sh --url https://github.com/${REPO} --token ${REG_TOKEN} --labels "terraform" #${RUNNER_LABELS}

# Cleanup function for SIGINT and SIGTERM signals
cleanup() {
    echo "Removing runner..."
    ./config.sh remove --unattended --token ${REG_TOKEN}
}

trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM

# Start runner
./run.sh & wait $!
