
resource "aws_iam_role" "IamRoleLambdaExecution" {
  name = "${var.StackNameDashes}-mailer-lambda-role"
  path = "/basic/"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  //permissions_boundary = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/Reece-BasicBoundaryPolicy"

  inline_policy {
    name = "${var.StackNameDashes}-mailer-lambda-role"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ]
          Effect   = "Allow"
          Resource = "*"
        },
        {
          Action = [
            "xray:GetSamplingRules",
            "xray:GetSamplingTargets",
            "xray:GetSamplingStatisticSummaries",
            "xray:BatchGetTraces",
            "xray:GetServiceGraph",
            "xray:GetTraceGraph",
            "xray:GetTraceSummaries",
            "xray:GetGroups",
            "xray:GetGroup",
            "xray:PutTraceSegments",
            "xray:PutTelemetryRecords"
          ]
          Effect   = "Allow"
          Resource = "*"
        },
        {
          Action   = "ses:SendEmail"
          Effect   = "Allow"
          Resource = "*"
        },
        {
          Action   = "s3:GetObject"          
          Effect   = "Allow"
          Resource = "arn:aws:s3:::${aws_s3_bucket.reece_s3_bucket.id}/*"
        }
      ]
    })
  }
}

data "archive_file" "lambda_zip_inline" {
  type        = "zip"
  output_path = "/tmp/lambda_zip_inline.zip"
  source {
    content  = <<EOF
var https = require('https');
var querystring = require('querystring');
var AWS = require("aws-sdk");

exports.handler = function(event, context, callback) {
  // Validate the recaptcha
  var input_data;
  try {
    input_data = JSON.parse(event.body);
  } catch (e) {
    input_data = event;
  }

  var postData = querystring.stringify({
    'secret': process.env.ReCaptchaSecret,
    'response': input_data['recaptcha']
  });

  var options = {
    hostname: 'www.google.com',
    port: 443,
    path: '/recaptcha/api/siteverify',
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
      'Content-Length': Buffer.byteLength(postData)
    }
  };

  var headers = {
    "Access-Control-Allow-Methods": "DELETE,GET,HEAD,OPTIONS,PATCH,POST,PUT",
    "Access-Control-Allow-Headers": "Content-Type,Authorization,X-Amz-Date,X-Api-Key,X-Amz-Security-Token",
    "Access-Control-Allow-Origin": "*", // Required for CORS support to work
    "Access-Control-Allow-Credentials": true // Required for cookies, authorization headers with HTTPS
  };

  var req = https.request(options, function(res) {
    res.setEncoding('utf8');
    res.on('data', function(chunk) {
      var captchaResponse = JSON.parse(chunk);
      if (captchaResponse.success) {
        var ses = new AWS.SES();
        var message = "";
        delete input_data['recaptcha'];
        Object.keys(input_data).forEach(function(key) {
          message += key + ': ';
          message += input_data[key] + '\n\n';
        });
        var params = {
          Destination: {
            ToAddresses: [
              process.env.ToEmailAddress
            ]
          },
          ReplyToAddresses: [
            process.env.ReplyToEmailAddress
          ],
          Message: {
            Body: {
              Text: {
                Data: message,
                Charset: 'UTF-8'
              }
            },
            Subject: {
              Data: process.env.Subject,
              Charset: 'UTF-8'
            }
          },
          Source: process.env.FromEmailAddress
        };

        ses.sendEmail(params, function(err, response) {
          if (err) {
            callback(null, {
              statusCode: '500',
              headers: headers,
              body: JSON.stringify({
                message: 'Error sending email'+err
              })
            });
          } else {
            callback(null, {
              statusCode: '200',
              headers: headers,
              body: JSON.stringify(response)
            });
          }
        });
      } else {
        callback(null, {
          statusCode: '500',
          headers: headers,
          body: JSON.stringify({
            message: 'Invalid recaptcha'
          })
        });
      }
    });
  });

  req.on('error', function(e) {
    callback(null, {
      statusCode: '500',
      headers: headers,
      body: JSON.stringify({
        message: e.message
      })
    });
  });

  // write data to request body
  req.write(postData);
  req.end();
};

EOF
    filename = "index.js"
  }
}


resource "aws_lambda_function" "ContactUsFunction" {
  function_name = "ContactUsFunction"
  handler       = "index.handler"
  role          = aws_iam_role.IamRoleLambdaExecution.arn
  runtime       = "nodejs14.x"

  environment {
    variables = {
      ReCaptchaSecret     = var.ReCaptchaSecret
      Subject             = var.Subject
      ToEmailAddress      = var.ToEmailAddress
      FromEmailAddress    = var.FromEmailAddress
      ReplyToEmailAddress = var.ReplyToEmailAddress
    }
  }

  filename         = data.archive_file.lambda_zip_inline.output_path
  source_code_hash = data.archive_file.lambda_zip_inline.output_base64sha256

  tracing_config {
    mode = "Active"
  }

  timeout = 5
}

resource "aws_api_gateway_rest_api" "ContactUs_api" {
  name        = "ContactUs-api" # Update with your desired API name
  description = "ContactUs API"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_resource" "ContactUs_resource" {
  rest_api_id = aws_api_gateway_rest_api.ContactUs_api.id
  parent_id   = aws_api_gateway_rest_api.ContactUs_api.root_resource_id
  path_part   = "contact-us"
}

resource "aws_api_gateway_method" "post_method" {
  rest_api_id   = aws_api_gateway_rest_api.ContactUs_api.id
  resource_id   = aws_api_gateway_resource.ContactUs_resource.id
  http_method   = "POST"
  authorization = "NONE" # Update with your desired authorization type

}
resource "aws_api_gateway_method" "options" {
  rest_api_id   = aws_api_gateway_rest_api.ContactUs_api.id
  resource_id   = aws_api_gateway_resource.ContactUs_resource.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_method_response" "options_response" {
  rest_api_id = aws_api_gateway_rest_api.ContactUs_api.id
  resource_id = aws_api_gateway_resource.ContactUs_resource.id
  http_method = aws_api_gateway_method.options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_method_response" "post_response" {
  rest_api_id = aws_api_gateway_rest_api.ContactUs_api.id
  resource_id = aws_api_gateway_resource.ContactUs_resource.id
  http_method = aws_api_gateway_method.post_method.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Credentials" = true,
    "method.response.header.Access-Control-Allow-Headers"     = true,
    "method.response.header.Access-Control-Allow-Methods"     = true,
    "method.response.header.Access-Control-Allow-Origin"      = true
  }

}

resource "aws_api_gateway_deployment" "deployment" {
  depends_on = [
    aws_api_gateway_integration.lambda_integration,
    aws_api_gateway_integration.options_integration, # Add this line
  ]

  rest_api_id = aws_api_gateway_rest_api.ContactUs_api.id
  stage_name  = var.stage
}


resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.ContactUs_api.id
  resource_id             = aws_api_gateway_resource.ContactUs_resource.id
  http_method             = aws_api_gateway_method.post_method.http_method
  integration_http_method = "POST"
  type                    = "AWS"
  passthrough_behavior    = "WHEN_NO_TEMPLATES"
  uri                     = aws_lambda_function.ContactUsFunction.invoke_arn
}

resource "aws_api_gateway_integration" "options_integration" {
  rest_api_id             = aws_api_gateway_rest_api.ContactUs_api.id
  resource_id             = aws_api_gateway_resource.ContactUs_resource.id
  http_method             = aws_api_gateway_method.options.http_method
  integration_http_method = "OPTIONS"
  type                    = "MOCK"
  passthrough_behavior    = "NEVER"
  uri                     = aws_lambda_function.ContactUsFunction.invoke_arn

  request_templates = {
    "application/json" = "{ \"statusCode\": 200 }"
  }
}

resource "aws_api_gateway_integration_response" "options_integration_response" {
  depends_on  = [aws_api_gateway_integration.options_integration]
  rest_api_id = aws_api_gateway_rest_api.ContactUs_api.id
  resource_id = aws_api_gateway_resource.ContactUs_resource.id
  http_method = aws_api_gateway_method.options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'OPTIONS,POST'",
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

}

resource "aws_api_gateway_integration_response" "lambda_integration_response" {
  depends_on  = [aws_api_gateway_integration.lambda_integration]
  rest_api_id = aws_api_gateway_rest_api.ContactUs_api.id
  resource_id = aws_api_gateway_resource.ContactUs_resource.id
  http_method = aws_api_gateway_method.post_method.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }
  response_templates = {
    "application/json" = ""
  }
}

resource "aws_lambda_permission" "apigw" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ContactUsFunction.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "arn:aws:execute-api:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.ContactUs_api.id}/*/POST/contact-us"
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}


