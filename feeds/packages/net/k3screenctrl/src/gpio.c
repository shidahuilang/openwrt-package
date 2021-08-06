#include <errno.h>
#include <stdio.h>

#include "common.h"
#include "file_util.h"
#include "gpio.h"

int gpio_export(int gpio) {
    char path_buf[50];

    sprintf(path_buf, "/sys/class/gpio/gpio%d", gpio);

    return path_exists(path_buf) == SUCCESS ||
           write_file_int("/sys/class/gpio/export", gpio);
}

int gpio_unexport(int gpio) {
    char path_buf[50];

    sprintf(path_buf, "/sys/class/gpio/gpio%d", gpio);

    return path_exists(path_buf) == FAILURE ||
           write_file_int("/sys/class/gpio/unexport", gpio);
}

int gpio_set_direction(int gpio, GPIO_DIRECTION dir) {
    char path_buf[50];
    char *dir_str;

    sprintf(path_buf, "/sys/class/gpio/gpio%d/direction", gpio);

    switch (dir) {
    case GPIO_IN:
        dir_str = "in";
        break;
    case GPIO_OUT:
        dir_str = "out";
        break;
    }

    return write_file_str(path_buf, dir_str);
}

int gpio_set_value(int gpio, int value) {
    char path_buf[50];

    sprintf(path_buf, "/sys/class/gpio/gpio%d/value", gpio);

    return write_file_int(path_buf, value);
}
