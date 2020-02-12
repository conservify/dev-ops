resource "aws_sqs_queue" "fk-messages-incoming" {
  name = "fk-messages-incoming"
}

resource "aws_s3_bucket" "fk-streams" {
  bucket = "fk-streams"
  acl = "private"
}

resource "aws_s3_bucket_policy" "fk-streams" {
  bucket = aws_s3_bucket.fk-streams.id

  policy = <<POLICY
{
	"Version": "2012-10-17",
	"Id": "Policy1234567890123",
	"Statement": [{
		"Sid": "Stmt1234567890123",
		"Effect": "Allow",
		"Principal": "*",
		"Action": "s3:*",
		"Resource": "arn:aws:s3:::fk-streams/*",
		"Condition": {
			"StringEquals": {
				"aws:sourceVpc": "${aws_vpc.fk.id}"
			}
		}
	}]
}
POLICY
}

resource "aws_s3_bucket" "fk-media" {
  bucket = "fk-media"
  acl = "private"
}

resource "aws_iam_role" "fk-server" {
  name = "fk-server"

  assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
	{
	  "Action": "sts:AssumeRole",
	  "Principal": {
		"Service": "ec2.amazonaws.com"
	  },
	  "Effect": "Allow"
	}
  ]
}
EOF
}

resource "aws_iam_instance_profile" "fk-server" {
  name = "fk-server"
  role = aws_iam_role.fk-server.name
}

resource "aws_iam_role_policy" "fk-server" {
  name   = "fk-server"
  role   = aws_iam_role.fk-server.id
  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": "ses:SendEmail",
            "Resource": "*",
            "Condition": {
                "StringEquals": {
                    "ses:FromAddress": [
                        "admin@fkdev.org",
                        "admin@fieldkit.org"
                    ]
                }
            }
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": [
                "sqs:DeleteMessage",
                "sqs:ReceiveMessage",
                "sqs:SendMessage"
            ],
            "Resource": [
                "arn:aws:sqs:us-east-1:238981173904:fk-messages-incoming"
            ]
        },
        {
            "Sid": "VisualEditor2",
            "Effect": "Allow",
            "Action": [
                "s3:GetObject"
            ],
            "Resource": [
                "arn:aws:s3:::conservify-firmware/*"
            ]
        },
        {
            "Sid": "VisualEditor3",
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:PutObject",
                "s3:PutObjectAcl",
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::fk-streams/*",
                "arn:aws:s3:::fk-media/*"
            ]
        },
        {
            "Sid": "VisualEditor4",
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::fk-streams",
                "arn:aws:s3:::fk-media"
            ]
        }
    ]
}
POLICY
}
