import boto3
import json
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    sqs = boto3.resource('sqs')
    incoming_queue = sqs.get_queue_by_name(QueueName='fk-messages-incoming')
    incoming_queue.send_message(MessageBody=json.dumps(event))

    return {
        'statusCode': '200',
        'body': json.dumps({ }),
        'headers': {
            'Content-Type': 'application/json',
        }
    }
