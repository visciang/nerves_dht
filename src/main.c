#include <stdio.h>
#include <stdlib.h>

#if defined(rpi)
#  include "rpi/pi_dht_read.h"
#  define PHT_READ pi_dht_read
#elif defined(rpi2)
#  include "rpi2/pi_2_dht_read.h"
#  define PHT_READ pi_2_dht_read
#elif defined(rpi3)
#  include "rpi3/pi_2_dht_read.h"
#  define PHT_READ pi_2_dht_read
#elif defined(rpi4)
#  include "rpi4/pi_2_dht_read.h"
#  define PHT_READ pi_2_dht_read
#elif defined(rpi0)
#  include "rpi0/pi_0_dht_read.h"
#  define PHT_READ pi_0_dht_read
#endif

static int parse_argv(int argc, char **argv, int *sensor, int *pin) {
    if (argc != 3) {
usage:
        fprintf(stderr,
            "usage: prog <sensor> <pin>\n"
            "  - sensor: dht11 | dht22 | am2302 for sensor model DHT11 | DHT22 | AM2302\n"
            "  - pin: GPIO pin (using BCM numbering)\n");
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

    result = PHT_READ(sensor, pin, &humidity, &temperature);
    if (result != 0) fprintf(stderr, "read error\n");

    printf("%f %f\n", humidity, temperature);

    return result;
}
