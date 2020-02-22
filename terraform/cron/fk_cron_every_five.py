import urllib2
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def handler(ev, ctx):
    logger.info('starting {}'.format(ev))
    logger.info("connecting...")

    try:
        body = urllib2.urlopen("https://api.fieldkit.org/tasks/five").read()
        logger.info(body)
    except urllib2.HTTPError as err:
        logger.info("error")
        logger.info(err)

    try:
        body = urllib2.urlopen("https://api.fkdev.org/tasks/five").read()
        logger.info(body)
    except urllib2.HTTPError as err:
        logger.info("error")
        logger.info(err)

if __name__ == "__main__":
    test = {}
    handler(test, None)
