#!/bin/bash

#
# Minio Installation Script
# 
# IMPORTANT: 
# Customize env-minio.sh and execute ". ./env-minio.sh" BEFORE running this script
# 

set -e

#######################################################################################################################
# Local variables
#######################################################################################################################

HELM_BIN=${HELM_BIN:-helm}

fileArchivePVC="minio-pv-claim"

#######################################################################################################################
# INSTALL
#######################################################################################################################
echo "Installing Minio $MINIO_VERSION"

# Create namespace if not available
echo "Checking namespace $NAMESPACE ..."

hasNamespace=`kubectl get ns ${NAMESPACE} 2>/dev/null || echo "NotFound"`
if [[ "$hasNamespace" == *'NotFound'* ]];
then
    kubectl create namespace ${NAMESPACE}
else
    echo "namespace $NAMESPACE exists"
fi

# Deploy Minio if it is not yet installed
echo "Checking Minio..."
hasMinio=`${HELM_BIN} status minio -n $NAMESPACE 2>/dev/null || echo "not found"`
if [[ "$hasMinio" == *'not found'* ]];
then
    echo "Creating pv minio-pv"
    hasPv=`kubectl get pv | grep minio-pv 2>/dev/null || echo "not found"`
    if [[ "$hasPv" == *'not found'* ]];
	then
		kubectl create -f minio-pv.yml
    	else
		echo "pv minio-pv already exists"
    fi
    echo "Creating minio pvc"
    hasPvc=`kubectl get pvc -n $NAMESPACE 2>/dev/null || echo "not found"`
    if [[ "$hasPvc" == *'not found'* || "$hasPvc" == *'No resources'* || "$hasPvc" == '' ]];
    then
	kubectl create -f minio-pvc.yml -n $NAMESPACE
	else
		echo "pvc minio-pvc already exists"
    fi
    echo "Creating minio deployment"
    kubectl create -f minio-deployment.yml -n $NAMESPACE
    echo "Creating minio service"
    kubectl create -f minio-service.yml -n $NAMESPACE
else
    echo "minio already deployed"
fi

#######################################################################################################################
# Wait for minio to come alive
#######################################################################################################################

echo "Waiting for minio pod in namespace ${NAMESPACE} to startup..."
pods=$(kubectl -n ${NAMESPACE} get pods -o wide | grep -v Completed | grep '0/1\|0/2\|1/2' | wc | awk '{print $1}')
while [ $pods -gt 0 ]
do
   echo "Unavailable pods: $pods"
   sleep 5
   pods=$(kubectl -n ${NAMESPACE} get pods -o wide | grep -v Completed | grep '0/1\|0/2\|1/2' | wc | awk '{print $1}')
done

echo "Startup completed!"
