import sys
import logging
import psycopg2
import json
import config
from urllib.parse import parse_qs
import binascii
import struct
import datetime
from pytz import timezone
import argparse

from_zone = timezone('UTC')
# to_zone = timezone('Africa/Gaborone')
to_zone = timezone('America/Los_Angeles')
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def encode_varint_stream(values):
    """Lazily encodes an iterable of Python integers to a VARINT stream."""
    for value in values:
        while True:
            if value > 127:
                # Yield a byte with the most-significant-bit (MSB) set plus 7
                # bits of data from the value.
                yield (1 << 7) | (value & 0x7f)

                # Shift to the right 7 bits to drop the data we've already
                # encoded. If we've encoded all the data for this value, set the
                # None flag.
                value >>= 7
            else:
                # This is either the last byte or only byte for the value, so
                # we don't set the MSB.
                yield value
                break

class BinaryMessage(bytearray):
    def append(self, v, fmt='>B'):
        self.extend(struct.pack(fmt, v))

    def varint(self, value):
        self.extend(encode_varint_stream([value]))

    def float(self, value):
        self.extend(struct.pack('>f', value))

class TextToBinary:
    def __init__(self, id_map, formats):
        self.id_map = id_map
        self.formats = formats

    def convert(self, transmission):
        key = transmission.stream_key()
        if not key in self.id_map:
            self.id_map[key] = len(self.id_map.keys()) + 1
        stream_id = self.id_map[key]
        self.formats[stream_id] = transmission.stream_key()

        message_fields = transmission.message_fields()

        buffer = BinaryMessage()
        buffer.varint(stream_id)
        buffer.varint(transmission.unix_time())
        for field in message_fields:
            buffer.float(float(field))
        return bytearray(buffer)

class Transmission:
    def __init__(self, fields, original):
        self.fields = fields
        self.original = original

    def transmission_time(self):
        return self.original['transmit_time'][0]

    def stream_key(self):
        return ','.join([self.fields[1], self.fields[2]])

    def message_fields(self):
        return self.fields[3:]

    def unix_time(self):
        return int(self.fields[0])

    def utc_time(self):
        return from_zone.localize(datetime.datetime.fromtimestamp(int(self.fields[0])))

    def local_time(self):
        utc = from_zone.localize(datetime.datetime.fromtimestamp(int(self.fields[0])))
        return utc.astimezone(to_zone)

    def raw(self):
        return ",".join(self.fields)

    def name(self):
        return self.fields[1]

    def battery(self):
        return float(self.fields[4])

    def is_v2(self):
        return self.fields[2] in "ST,WE,LO,AT,SO"

class TransmissionsParser:
    def __init__(self):
            pass

    def from_database_row(self, row):
        data = row[2]
        form = parse_qs(data['body-raw']) 
        # print(form)
        if form.get('imei'):
            if form.get('data'):
                protocol_id = form['momsn']
                message_raw = binascii.a2b_hex(form['data'][0]).decode('utf8')
                fields = message_raw.split(',')
                return Transmission(fields, form)

class StationStatus:
    def __init__(self, name):
        self.name = name
        self.time = None
        self.battery = None
        self.number_of_messages = 0

    def update(self, transmission):
        self.time = transmission.local_time()
        self.battery = transmission.battery()
        self.number_of_messages += 1

    def age(self):
        local_now = from_zone.localize(datetime.datetime.utcnow()).astimezone(to_zone)
        # print(local_now.strftime("%x %X"))
        return local_now - self.time

    def log(self):
        row = " | ".join([ self.name, str(self.age()), self.time.strftime("%x %X"), str(self.number_of_messages), str(self.battery) ])
        print("| " + row + " |")

class DashboardStatus:
    def __init__(self):
        self.statuses = {}

    def update(self, transmission):
        station = self.statuses.setdefault(transmission.name(), StationStatus(transmission.name()))
        station.update(transmission)

    def log(self):
        for station, status in sorted(self.statuses.items(), key=lambda x: x[1].age()):
            status.log()

if __name__ == "__main__":
    logging.basicConfig(format='%(levelname)s %(message)s', level=logging.DEBUG)

    parser = argparse.ArgumentParser(description='Transmissions helper.')
    # parser.add_argument('--configure', dest='configure')
    # parser.add_argument('--archive', dest='archive', const=True, action='store_const')
    # parser.add_argument('--watch', dest='watch', const=True, action='store_const')
    args = parser.parse_args()

    with psycopg2.connect(host=config.hostname, database="messages", user=config.user, password=config.password) as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT * FROM messages_raw WHERE time > '2017-02-21' ORDER BY time")
            parser = TransmissionsParser()
            dashboard = DashboardStatus()
            ids = { }
            formats = {}
            textToBinary = TextToBinary(ids, formats)
            for row in cur.fetchall():
                transmission = parser.from_database_row(row)
                if transmission and transmission.is_v2():
                    print(transmission.transmission_time() + " " + transmission.local_time().strftime("%x %X") + "," + transmission.raw())
                    binary = textToBinary.convert(transmission)
                    # print(binascii.hexlify(binary).decode('utf8'))
                    dashboard.update(transmission)

            dashboard.log()
