#!/usr/bin/python3

import argparse
import logging
import sys
import os

log = logging.getLogger("cfystartup")

def flatten(l):
    return [item for sl in l for item in sl]

def main():
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s [%(levelname)s] %(message)s",
        handlers=[logging.StreamHandler()],
    )

    parser = argparse.ArgumentParser(description="startup tool")
    parser.add_argument("--urls", dest="urls", nargs="*", default=[], help="", type=str)
    args, nargs = parser.parse_known_args()

    for url in flatten([url.split(",") for url in args.urls]):
        log.info("downloading %s" % (url),)
        os.system("wget -q --auth-no-challenge '%s'" % (url,))
        log.info("done downloading %s" % (url),)

if __name__ == "__main__":
    main()

