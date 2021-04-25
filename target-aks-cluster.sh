#!/bin/bash
echo "Did you connect to your target AKS cluster and define these varibales the script: TENANT_ID, SUBSCRIPTION_ID, TARGET_AKS_INFRASTRUCTURE_RESOURCE_GROUP, BACKUP_STORAGE_ACCOUNT_NAME?(yes/no)"
read input

if [ "$input" == "yes" ]
then

#Define the variables.
TENANT_ID="TENANT_ID" 
SUBSCRIPTION_ID="SUBSCRIPTION_ID" 
BACKUP_RESOURCE_GROUP=Velero_Backups
BACKUP_STORAGE_ACCOUNT_NAME="BACKUP_STORAGE_ACCOUNT_NAME"
VELERO_SP_DISPLAY_NAME="velerospn"
TARGET_AKS_INFRASTRUCTURE_RESOURCE_GROUP="TARGET_AKS_INFRASTRUCTURE_RESOURCE_GROUP"

#Set permissions for Velero on TARGET_AKS_INFRASTRUCTURE_RESOURCE_GROUP
echo "Setting permissions for Velero..."
AZURE_CLIENT_ID=`az ad sp list --display-name $VELERO_SP_DISPLAY_NAME --query '[0].appId' -o tsv`
AZURE_CLIENT_SECRET=`az ad sp credential reset --name $VELERO_SP_DISPLAY_NAME --append --query 'password' -o tsv`
az role assignment create  --role Contributor --assignee $AZURE_CLIENT_ID --scope /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$TARGET_AKS_INFRASTRUCTURE_RESOURCE_GROUP

#Save Velero credentials to local file.
echo "Saving velero credentials to local file: credentials-velero-target..."
cat << EOF  > ./credentials-velero-target
AZURE_SUBSCRIPTION_ID="${SUBSCRIPTION_ID}"
AZURE_TENANT_ID="${TENANT_ID}"
AZURE_CLIENT_ID="${AZURE_CLIENT_ID}"
AZURE_CLIENT_SECRET="${AZURE_CLIENT_SECRET}"
AZURE_RESOURCE_GROUP="${TARGET_AKS_INFRASTRUCTURE_RESOURCE_GROUP}"
AZURE_CLOUD_NAME=AzurePublicCloud
EOF

##Install Velero, uncomment this part in case you don't have Velero on your machine.
#echo "Installing Velero client locally..."
#latest_version=`curl https://github.com/vmware-tanzu/velero/releases/latest`
#latest_version=`echo $latest_version | grep -o 'v[0-9].[0-9].[0.9]'`
#wget https://github.com/vmware-tanzu/velero/releases/download/$latest_version/velero-$latest_version-linux-amd64.tar.gz
#mkdir ~/velero; tar -zxf velero-$latest_version-linux-amd64.tar.gz -C ~/velero
#mv ~/velero/velero-$latest_version-linux-amd64/velero /usr/bin/

#Stare Velero on target AKS cluster
echo "Staring Velero on target AKS cluster..."
velero install \
  --provider azure \
  --plugins velero/velero-plugin-for-microsoft-azure:v1.0.0 \
  --bucket velero \
  --secret-file ./credentials-velero-target \
  --backup-location-config resourceGroup=$BACKUP_RESOURCE_GROUP,storageAccount=$BACKUP_STORAGE_ACCOUNT_NAME \
  --snapshot-location-config apiTimeout=5m,resourceGroup=$BACKUP_RESOURCE_GROUP \
  --wait
  
else
echo "Please connect to your target AKS cluster, open the bash script and define the variables before running the script."
exit 0
fi