#!/usr/bin/python3

import sys
import argparse
import logging
import re
import urllib.parse
import json
import boto3


def get_keys_from_file(file, keys):
    for line in file:
        for m in re.findall(r"(https://([^\.]+).s3.amazonaws.com/([^\s]+))", line):
            bucket = m[1]
            parsed = urllib.parse.urlparse(m[0])
            if parsed:
                key = parsed.path[1:]
                keys.setdefault(bucket, []).append(m[2])
    return keys


if __name__ == "__main__":
    logging.basicConfig(stream=sys.stdout, level=logging.INFO)
    log = logging.getLogger("harvest-keys")

    parser = argparse.ArgumentParser(description="s3 key tool")
    parser.add_argument("--delete", action="store_true", default=False)
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

    if args.delete:
        cl = boto3.client("s3")
        for bucket in keys:
            logging.info("deleting from {}".format(bucket))
            bucket_keys = keys[bucket]
            object_entries = [{"Key": key} for key in keys[bucket]]
            response = cl.delete_objects(
                Bucket=bucket, Delete={"Objects": object_entries, "Quiet": False,},
            )
