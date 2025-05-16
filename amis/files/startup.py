#!/usr/bin/python3

import argparse
import logging
import sys
import os
import re

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
        log.info(f"downloading {url}")
        command = f"wget -q --auth-no-challenge '{url}'"
        # try and guess filename from url, just in case we end up with a strangely named file.
        if m := re.search(r'[\w\d_-]+\.tar', url):
            name = m.group(0)
            log.info(f"using file name {name}")
            command += f" -O '{name}'"
            log.info(f"command: {command}")
        output = os.system(command)
        log.info(output)
        log.info(f"done downloading {url}")

if __name__ == "__main__":
    main()

