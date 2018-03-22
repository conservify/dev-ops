import urllib2
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def handler(ev, ctx):
    try:
        logger.info('Starting {}'.format(ev))
        logger.info("Connecting...")
        body = urllib2.urlopen("http://api.fkdev.org/tasks/check").read()
        logger.info(body)
    except urllib2.HTTPError as err:
        logger.info("Error")
        logger.info(err)

if __name__ == "__main__":
    test = {}
    handler(test, None)
