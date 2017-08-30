#!/bin/sh

echo "$DHT_HUMIDITY $DHT_TEMPERATURE"
printf "." >> /tmp/dht_call_count
exit $DHT_EXIT
