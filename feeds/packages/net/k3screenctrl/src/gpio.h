#ifndef _GPIO_H
#define _GPIO_H

typedef enum _gpio_dir { GPIO_IN, GPIO_OUT } GPIO_DIRECTION;

int gpio_export(int gpio);
int gpio_unexport(int gpio);
int gpio_set_direction(int gpio, GPIO_DIRECTION dir);
int gpio_set_value(int gpio, int value);

#endif
