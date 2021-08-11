#ifndef _ACTIONS_H
#define _ACTIONS_H

#include "mcu_proto.h"

void page_send_initial_data();
void page_update();
void page_switch_next();
void page_switch_prev();
void page_switch_to(PAGE page);
void page_refresh();

#endif
