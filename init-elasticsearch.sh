!#/bin/bash
###############################################################################
## AWS EC2 User Data Initialization script
##
## Usage:
##  Run on Amazon, Redhat, or CentOS instances
##
##  Enter the lines below into the User data textbox to run this script at EC2 Startup time:
##    !/bin/bash
##    sudo su -
##    aws s3 cp   s3://your-script-bucket.domain.com/init-elasticsearch.sh   .
##    bash ./init-elasticsearch.sh
##
## Author: Bob Brady <bob@digibrady.com>
##
###############################################################################
yum -y update

# Make sure JVM is up-to-date for Elasticsearch, install helper utils
yum -y remove java-1.7.0-openjdk
yum -y install java-1.8.0-openjdk jq wget

# Download and install Elasticsearch
# TODO: We could get the rpm from S3
wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-6.2.4.rpm
rpm -ivh elasticsearch-6.2.4.rpm
chkconfig --add elasticsearch

# Download and copy Elasticsearch config template
aws s3 cp s3://<your-s3-bucket-name.domain.com>/elasticsearch/elasticsearch-template.yml /etc/elasticsearch/elasticsearch.yml

# Install AWS EC2 plugin, use the "-b" batch switch to enable permissions by default
cd /usr/share/elasticsearch
./bin/elasticsearch-plugin install -b discovery-ec2
cd /etc/elasticsearch

# Get runtime config data from AWS
curl -s http://169.254.169.254/latest/dynamic/instance-identity/document -o instance-identify.json
INSTANCE_ID=$(cat instance-identify.json | jq -r .instanceId)
AVAIL_ZONE=$(cat instance-identify.json | jq -r .availabilityZone)
REGION=$(cat instance-identify.json | jq -r .region)

# Set other config data
CLUSTER_NAME=<your-cluster-name>
SECURITY_GROUP_NAME=<your-security-group-name>

echo "AWS Elasticsearch Runtime Settings for This Node"
echo "Instance ID: $INSTANCE_ID"
echo "Availability Zone: $AVAIL_ZONE"
echo "Region: $REGION"

echo "Substituting Runtime Settings in Config YAML..."
sed -i -- "s/INPUT_INSTANCE_NAME/$INSTANCE_ID/" elasticsearch.yml
sed -i -- "s/INPUT_REGION/$REGION/" elasticsearch.yml
sed -i -- "s/INPUT_AVAIL_ZONE/$AVAIL_ZONE/" elasticsearch.yml
sed -i -- "s/INPUT_CLUSTER_NAME/$CLUSTER_NAME/" elasticsearch.yml
sed -i -- "s/INPUT_SECURITY_GROUP_NAME/$SECURITY_GROUP_NAME/" elasticsearch.yml

cat elasticsearch.yml
service elasticsearch start
