data "aws_iam_policy_document" "fk-server" {
  /*
  statement {
    actions = [
      "sqs:SendMessage",
      "sqs:DeleteMessage",
      "sqs:ReceiveMessage",
    ]

    resources = [
      "${aws_sqs_queue.fk.arn}",
    ]
  }
  */

  statement {
    actions = [
      "ses:SendEmail",
    ]

    resources = [
      "*",
    ]

    condition {
      test     = "StringEquals"
      variable = "ses:FromAddress"

      values = [
        "admin@fieldkit.org",
        "admin@fkdev.org",
      ]
    }
  }
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
  role = "${aws_iam_role.fk-server.name}"
}

resource "aws_iam_role_policy" "fk-server" {
  name   = "fk-server"
  role   = "${aws_iam_role.fk-server.id}"
  policy = "${data.aws_iam_policy_document.fk-server.json}"
}
