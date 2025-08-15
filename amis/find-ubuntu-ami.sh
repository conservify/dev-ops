#!/bin/bash

export AWS_DEFAULT_REGION=us-east-1

aws ec2 describe-images \
 --filters Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-*-22.04-amd64* \
 --query 'Images[*].[ImageId,Name,CreationDate]' --output text \
 | sort -k2 -r \
 | head -n1
