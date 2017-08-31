#!/bin/bash

# Defaults
DHT_HUMIDITY="${DHT_HUMIDITY:-55.1}"
DHT_TEMPERATURE="${DHT_TEMPERATURE:-24.719}"

echo "$DHT_HUMIDITY $DHT_TEMPERATURE"
printf "." >> /tmp/dht_call_count
exit $DHT_EXIT
