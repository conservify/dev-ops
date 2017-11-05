resource "aws_sqs_queue" "fk-messages-incoming" {
  name = "fk-messages-incoming"
}

data "aws_iam_policy_document" "lambda_fk_enqueue_policy" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [ "arn:aws:logs:*:*:*" ]
  }
  statement {
    actions = [
      "sqs:SendMessage",
      "sqs:GetQueueUrl"
    ]
    resources = [ "${aws_sqs_queue.fk-messages-incoming.arn}" ]
  }
}

resource "aws_iam_role" "lambda_fk_enqueue_role" {
  name = "lambda_fk_enqueue_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "lambda_fk_enqueue_role_policy" {
  name = "lambda_fk_enqueue_role_policy"
  role = "${aws_iam_role.lambda_fk_enqueue_role.id}"
  policy = "${data.aws_iam_policy_document.lambda_fk_enqueue_policy.json}"
}

resource "aws_lambda_permission" "lambda_api_gateway_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.lambda_fk_enqueue.arn}"
  principal = "apigateway.amazonaws.com"

  # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  source_arn = "arn:aws:execute-api:${var.region}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.fk-api-incoming.id}/*/${aws_api_gateway_method.fk-api-incoming-messages-enqueue-method.http_method}${aws_api_gateway_resource.fk-api-incoming-messages.path}"
}

resource "aws_lambda_function" "lambda_fk_enqueue" {
  filename = "fk_enqueue.zip"
  function_name = "fk_enqueue"
  role = "${aws_iam_role.lambda_fk_enqueue_role.arn}"
  handler = "enqueue.lambda_handler"
  source_code_hash = "${base64sha256(file("fk_enqueue.zip"))}"
  runtime = "python2.7"
}

resource "aws_api_gateway_rest_api" "fk-api-incoming" {
  name = "fk-api-incoming"
  description = ""
}

resource "aws_api_gateway_resource" "fk-api-incoming-messages" {
  rest_api_id = "${aws_api_gateway_rest_api.fk-api-incoming.id}"
  parent_id = "${aws_api_gateway_rest_api.fk-api-incoming.root_resource_id}"
  path_part = "messages"
}

resource "aws_api_gateway_method" "fk-api-incoming-messages-enqueue-method" {
  rest_api_id = "${aws_api_gateway_rest_api.fk-api-incoming.id}"
  resource_id = "${aws_api_gateway_resource.fk-api-incoming-messages.id}"
  http_method = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "fk-api-incoming-messages-enqueue" {
  rest_api_id = "${aws_api_gateway_rest_api.fk-api-incoming.id}"
  resource_id = "${aws_api_gateway_resource.fk-api-incoming-messages.id}"
  http_method = "${aws_api_gateway_method.fk-api-incoming-messages-enqueue-method.http_method}"
  type = "AWS_PROXY"
  uri = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${aws_lambda_function.lambda_fk_enqueue.arn}/invocations"
  integration_http_method = "POST"

  request_templates {
    "application/x-www-form-urlencoded" = <<EOF
##  See http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-mapping-template-reference.html
##  This template will pass through all parameters including path, querystring, header, stage variables, and context through to the integration endpoint via the body/payload
#set($allParams = $input.params())
{
"body-raw" : "$input.path('$')",
"params" : {
#foreach($type in $allParams.keySet())
    #set($params = $allParams.get($type))
"$type" : {
    #foreach($paramName in $params.keySet())
    "$paramName" : "$util.escapeJavaScript($params.get($paramName))"
        #if($foreach.hasNext),#end
    #end
}
    #if($foreach.hasNext),#end
#end
},
"stage-variables" : {
#foreach($key in $stageVariables.keySet())
"$key" : "$util.escapeJavaScript($stageVariables.get($key))"
    #if($foreach.hasNext),#end
#end
},
"context" : {
    "account-id" : "$context.identity.accountId",
    "api-id" : "$context.apiId",
    "api-key" : "$context.identity.apiKey",
    "authorizer-principal-id" : "$context.authorizer.principalId",
    "caller" : "$context.identity.caller",
    "cognito-authentication-provider" : "$context.identity.cognitoAuthenticationProvider",
    "cognito-authentication-type" : "$context.identity.cognitoAuthenticationType",
    "cognito-identity-id" : "$context.identity.cognitoIdentityId",
    "cognito-identity-pool-id" : "$context.identity.cognitoIdentityPoolId",
    "http-method" : "$context.httpMethod",
    "stage" : "$context.stage",
    "source-ip" : "$context.identity.sourceIp",
    "user" : "$context.identity.user",
    "user-agent" : "$context.identity.userAgent",
    "user-arn" : "$context.identity.userArn",
    "request-id" : "$context.requestId",
    "resource-id" : "$context.resourceId",
    "resource-path" : "$context.resourcePath"
    }
}
EOF
  }
}

resource "aws_api_gateway_method_response" "fk-api-incoming-messages" {
  rest_api_id = "${aws_api_gateway_rest_api.fk-api-incoming.id}"
  resource_id = "${aws_api_gateway_resource.fk-api-incoming-messages.id}"
  http_method = "${aws_api_gateway_method.fk-api-incoming-messages-enqueue-method.http_method}"
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration_response" "fk-api-incoming-messages-enqueue" {
  depends_on = [ "aws_api_gateway_integration.fk-api-incoming-messages-enqueue" ]
  rest_api_id = "${aws_api_gateway_rest_api.fk-api-incoming.id}"
  resource_id = "${aws_api_gateway_resource.fk-api-incoming-messages.id}"
  http_method = "${aws_api_gateway_method.fk-api-incoming-messages-enqueue-method.http_method}"
  status_code = "${aws_api_gateway_method_response.fk-api-incoming-messages.status_code}"

  response_templates {
    "application/json" = ""
  }
}

resource "aws_api_gateway_deployment" "fk-api-incoming" {
  depends_on = [
    "aws_api_gateway_method.fk-api-incoming-messages-enqueue-method",
    "aws_api_gateway_integration.fk-api-incoming-messages-enqueue",
    "aws_api_gateway_integration_response.fk-api-incoming-messages-enqueue"
  ]
  rest_api_id = "${aws_api_gateway_rest_api.fk-api-incoming.id}"
  stage_name = "test"
}

resource "aws_api_gateway_stage" "fk-api-incoming" {
  rest_api_id = "${aws_api_gateway_rest_api.fk-api-incoming.id}"
  deployment_id = "${aws_api_gateway_deployment.fk-api-incoming.id}"
  stage_name = "production"
}
