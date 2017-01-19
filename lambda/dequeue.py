import sys
import logging
import psycopg2
import json
import config
import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    logger.info('Starting {}'.format(event))

    sqs = boto3.resource('sqs')

    queue = sqs.get_queue_by_name(QueueName='messages-incoming')

    logger.info("Connecting to database...")

    with psycopg2.connect(host=config.hostname, database="messages", user=config.user, password=config.password) as conn:
        with conn.cursor() as cur:
            logger.info("Creating schema...")

            cur.execute("CREATE TABLE IF NOT EXISTS messages_raw (id SERIAL PRIMARY KEY, sqs_id VARCHAR NOT NULL, data JSON NOT NULL, hash VARCHAR NOT NULL)")

            logger.info("Receiving messages...")

            processed = []
            for message in queue.receive_messages(WaitTimeSeconds=10, MaxNumberOfMessages=10, MessageAttributeNames=['MessageId', 'MD5OfBody']):
                logger.info("Inserting {}".format(message.message_id))
                cur.execute("INSERT INTO messages_raw (sqs_id, data, hash) VALUES (%(sqs_id)s, %(data)s, %(hash)s)", {
                    'data': message.body,
                    'sqs_id': message.message_id,
                    'hash': message.md5_of_body
                })
                processed.append({
                    'Id': message.message_id,
                    'ReceiptHandle': message.receipt_handle
                })

            conn.commit()

            logger.info("Deleting {} messages...".format(len(processed)))
            if len(processed) > 0:
                queue.delete_messages(Entries=processed)

            cur.execute("SELECT COUNT(*) FROM  messages_raw")

            logger.info("DONE {}".format(cur.fetchone()[0]))

    return "Ok"
