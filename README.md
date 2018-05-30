# AWS Elasticsearch Cluster Quick-Start

This project aims to provide the documentation, scripts, and configuration for the quick deployment of a three-node Elasticsearch cluster in the Amazon cloud.

## Create an IAM role for the EC2 Elasticsearch nodes

An EC2 role with the following policy will enable the discover-ec2 es plug-in to associate ec2 details like private IP address, security groups, and so on with as part of the Elasticsearch configuration.

__Step 1: Create a Policy with EC2 permissions__
```
// IAM > Policies > Create policy > Select JSON tab > Paste JSON below > Click Review policy > Save
{
  "Statement": [
    {
      "Action": [
        "ec2:DescribeInstances"
      ],
      "Effect": "Allow",
      "Resource": [
        "*"
      ]
    }
  ],
  "Version": "2012-10-17"
}
```

__Step 2: Create a Policy with S3 permissions__
```
// IAM > Policies > Create policy > Select JSON tab > Paste JSON below > Click Review policy > Save
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::your-script-bucket.domain.com"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:GetObject",
                "s3:DeleteObject"
            ],
            "Resource": [
                "arn:aws:s3:::your-script-bucket.domain.com/*"
            ]
        }
    ]
}
```

__Step 3: Create an EC2 instance Role with the above policy__
```
// IAM > Roles > Create Role > Choose "EC2" service link > Click Next:Permissions > Select above Permissions
```
Assign this role to any Elasticsearch node instance when you are creating its launch configuration.

## Configure CLUSTER_NAME and SECURITY_GROUP_NAME
There is a file `init-elasticsearch.sh` in this project that will be pulled down from S3 by the EC2 host at start-up.  Edit the file's `CLUSTER_NAME` and `SECURITY_GROUP_NAME` to meet your needs for your Elasticsearch cluster name and the name of the AWS EC2 security group that will be associated with the node.


## Upload Config Template and Init Script to S3
The EC2 node will have a user data script that pulls the shell script to init the instance.  The init script will then install Elasticsearch and all needed packages.  It will use Linux `sed` to replace template placeholder values with runtime metadata from AWS (e.g., instance ID, region, and availability zone) as well as your suppplied cluster name and security group name.  You can find the files in this project:

* elasticsearch-template.yml => The template configuration with placeholders
* init-elasticsearch.sh => The EC2 init script
