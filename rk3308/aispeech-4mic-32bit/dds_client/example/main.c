#include "dui.h"
#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>

int main(int argc, char **argv) {
    FILE *fd = fopen(argv[1], "rb");
    fseek(fd, 0L, SEEK_END);
    int len = ftell(fd);
    char *buf = (char *)malloc(len + 1);
    fseek(fd, 0L, SEEK_SET);
    fread(buf, 1, len, fd);


    dui_library_init(buf, NULL);
    dui_start_recorder();
    while (1) {
        sleep(20);
    }
    dui_stop_recorder();
    dui_library_cleanup();
    return 0;
}
