#!/bin/bash

#
# Minio Uninstallation Script
#

set -e

namespace="${NAMESPACE:-minio}"

echo "Deletion of namespace: \"$namespace\" will commence in 10 seconds..."
echo "If this is not correct press Ctrl+C to exit now!"
sleep 10

kubectl delete namespace $namespace

kubectl delete pv minio-pv

echo "Deleted minio components and its namespace: $namespace"


