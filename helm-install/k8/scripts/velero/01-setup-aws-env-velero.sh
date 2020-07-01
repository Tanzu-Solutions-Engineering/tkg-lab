
echo 'Setup AWS Env for Velero'

export AWS_ACCESS_KEY_ID=$(yq r ./params.yml aws.access-key-id)
export AWS_SECRET_ACCESS_KEY=$(yq r ./params.yml aws.secret-access-key)
export AWS_BUCKET=$(yq r ./params.yml svcCluster.velero-bucket)
export AWS_REGION=$(yq r ./params.yml aws.region)

echo 'AWS Bucket:' $AWS_BUCKET ' in Region:' $AWS_REGION

# Creating Bucket

aws s3api create-bucket --bucket $AWS_BUCKET --region $AWS_REGION --create-bucket-configuration LocationConstraint=$AWS_REGION


aws s3 ls | grep $AWS_BUCKET

# Create the IAM User and attach policies to it.

aws iam create-user --user-name velero

# Create Velero User Policy

cat > velero-policy.json <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeVolumes",
                "ec2:DescribeSnapshots",
                "ec2:CreateTags",
                "ec2:CreateVolume",
                "ec2:CreateSnapshot",
                "ec2:DeleteSnapshot"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:DeleteObject",
                "s3:PutObject",
                "s3:AbortMultipartUpload",
                "s3:ListMultipartUploadParts"
            ],
            "Resource": [
                "arn:aws:s3:::${BUCKET}/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::${BUCKET}"
            ]
        }
    ]
}
EOF

# Add Velero User Policy

aws iam put-user-policy \
  --user-name velero \
  --policy-name velero \
  --policy-document file://velero-policy.json

# Create Access Key for Velero

aws iam create-access-key --user-name velero  --output json > aws-valero-access-key.json

# Save the creds

cat > credentials-velero <<EOF
[default]
aws_access_key_id= $(yq r aws-valero-access-key.json AccessKey.AccessKeyId)
aws_secret_access_key= $(yq r aws-valero-access-key.json AccessKey.SecretAccessKey)
EOF
