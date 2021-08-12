#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <string.h>
#include <sys/mman.h>
#include <syslog.h>
#include <unistd.h>

#include "common.h"

static int mask_begin_bit(int mask) {
    for (int i = 0; i < 8; i++) {
        if ((mask & (1 << i)) != 0) {
            return i;
        }
    }
    return 0;
}

int mask_memory_byte(off_t addr, int mask, int field_value) {
    int memfd = open("/dev/mem", O_RDWR);
    if (memfd < 0) {
        syslog(LOG_ERR, "Unable to access memory: %s", strerror(errno));
        return FAILURE;
    }

    off_t page_size = sysconf(_SC_PAGESIZE);
    off_t map_start = addr & ~(page_size - 1);
    off_t data_offset = addr - map_start;

    void *map_addr = mmap(NULL, page_size, PROT_READ | PROT_WRITE, MAP_SHARED,
                          memfd, map_start);
    if (map_addr == (void *)-1) {
        syslog(LOG_ERR, "Unable to mmap: %s", strerror(errno));
        close(memfd);
        return FAILURE;
    }

    void *virt_addr = map_addr + data_offset;
    unsigned char current_byte = *((unsigned char *)virt_addr);
    unsigned char data =
        (current_byte & ~mask) | (field_value << mask_begin_bit(mask));
    if (current_byte == data) {
        goto exit;
    }

    *((unsigned char *)virt_addr) = data;
    unsigned char read_result = *((unsigned char *)virt_addr);

    if (read_result != data) {
        syslog(LOG_INFO, "Written %llx with %hhx but read %hhx back\n", addr,
               data, read_result);
    }

exit:
    munmap(map_addr, page_size);
    close(memfd);
    return SUCCESS;
}
