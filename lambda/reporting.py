import sys
import logging
import psycopg2
import json
import config

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    logger.info("Connecting to database...")

    with psycopg2.connect(host=config.hostname, database="messages", user=config.user, password=config.password) as conn:
        with conn.cursor() as cur:
            logger.info("Querying...")

            cur.execute("SELECT COUNT(*) FROM messages_raw")

            logger.info("Number of messages: {}".format(cur.fetchone()[0]))

    return "Ok"
