#!/bin/bash
set -e

# Add local bin to PATH if it exists
if [ -d "$(dirname "$0")/bin" ]; then
    export PATH="$(dirname "$0")/bin:$PATH"
fi

echo "Starting port forwarding..."
# Kill any existing port-forward
pkill -f "kubectl port-forward" || true
kubectl port-forward svc/cloud-resource-service 8080:80 > /dev/null 2>&1 &
PF_PID=$!
sleep 5

echo "Starting load generation..."
# Generate load for 120 seconds to give HPA time to react
DURATION=120
end=$((SECONDS+DURATION))

# Run load generator in background
# Multiple threads/processes to ensure CPU goes up
LOAD_PIDS=""
for i in {1..4}; do
    (
        while [ $SECONDS -lt $end ]; do
            curl -s http://localhost:8080/load > /dev/null
        done
    ) &
    LOAD_PIDS="$LOAD_PIDS $!"
done

echo "Monitoring HPA for $DURATION seconds..."
# Loop kubectl get hpa
for i in $(seq 1 24); do
    echo "--- Time: $(date) ---"
    kubectl get hpa
    kubectl get pods -l app=cloud-resource-app
    sleep 5
done

echo "Stopping load..."
kill $LOAD_PIDS || true
kill $PF_PID || true

echo "Verification finished."
