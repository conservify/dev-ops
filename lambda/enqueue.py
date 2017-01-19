import boto3
import json
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    sqs = boto3.resource('sqs')
    backup_queue = sqs.get_queue_by_name(QueueName='messages-backup')
    backup_queue.send_message(MessageBody=json.dumps(event))
    incoming_queue = sqs.get_queue_by_name(QueueName='messages-incoming')
    incoming_queue.send_message(MessageBody=json.dumps(event))
