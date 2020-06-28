#!/usr/bin/python3

import sys
import argparse
import logging
import csv
import re
import urllib.parse
import json


def get_keys_from_file(file, keys):
    reader = csv.reader(file)
    for row in reader:
        for column in row:
            m = re.search(r"/([\w-]+)\.s3", column)
            if m:
                bucket = m[1]
                parsed = urllib.parse.urlparse(column)
                if parsed:
                    key = parsed.path[1:]
                    keys.setdefault(bucket, []).append(key)
    return keys


if __name__ == "__main__":
    logging.basicConfig(stream=sys.stdout, level=logging.INFO)
    log = logging.getLogger("harvest-keys")

    parser = argparse.ArgumentParser(description="s3 key tool")
    parser.add_argument("file", type=argparse.FileType("r"), nargs="+")
    args = parser.parse_args()

    keys = {}
    for file in args.file:
        logging.info("processing {}".format(file))
        keys = get_keys_from_file(file, keys)

    with open("keys.json", "w") as file:
        file.write(json.dumps(keys))

    for bucket in keys:
        with open(bucket + ".keys", "w") as file:
            for key in keys[bucket]:
                file.write("{}\n".format(key))
