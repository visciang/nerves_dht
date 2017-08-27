#include <stdio.h>
#include <stdlib.h>
#include "pi_2_dht_read.h"

static int parse_argv(int argc, char **argv, int *sensor, int *pin) {
    if (argc != 3) {
usage:
        fprintf(stderr,
            "usage: prog <sensor> <pin>\n"
            "  - sensor: 11 | 22 | 2302 for sensor model DHT11 | DHT22 | AM2302\n"
            "  - pin: gpio pin number\n");
        return -1;
    }

    *sensor = atoi(argv[1]);
    if (*sensor == 11)
        *sensor = DHT11;
    else if (*sensor == 22)
        *sensor = DHT22;
    else if (*sensor == 2302)
        *sensor = AM2302;
    else
        goto usage;

    *pin = atoi(argv[2]);

    return 0;
}

int main(int argc, char **argv) {
    int sensor, pin, result;
    float humidity, temperature;

    result = parse_argv(argc, argv, &sensor, &pin);
    if (result != 0) return -1;

    result = pi_2_dht_read(sensor, pin, &humidity, &temperature);
    if (result != 0) fprintf(stderr, "read error\n");

    printf("%f %f\n", humidity, temperature);

    return result;
}
