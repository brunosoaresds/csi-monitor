#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <limits.h>
#include <time.h>
#include <pthread.h>
#include <sys/types.h>
#include <sys/stat.h>

#include "csi_collector.h"
#include "csi_fun.h"

#define BUFSIZE 4096
#define FILE_TIME_SEC 1
#define MAX_FILES 10

unsigned char buf_addr[BUFSIZE];
int ready_to_write = FALSE;
int ready_to_init = FALSE;
FILE* write_file;
char stored_files[MAX_FILES][512];
int file_index = 0;

void *collect_csi_data(void *vargp) {
    csi_struct* csi_status = (csi_struct*)malloc(sizeof(csi_struct));
    int csi_cnt_bytes, csi_device_fd;
    u_int16_t   buf_len;
    pthread_t tid, tid2;

    /* Create file manager and files_cleaner */
    pthread_create(&tid, NULL, files_cleaner, NULL);
    pthread_create(&tid2, NULL, file_manager, NULL);

    /* Create device reading */
    csi_device_fd = open_csi_device();
    if (csi_device_fd < 0) {
        printf("Failed to open the CSI device...\n");
        exit(0);
    }

    while(TRUE) {
        /* keep listening the kernel until csi report */
        do {
            csi_cnt_bytes = read_csi_buf(buf_addr, csi_device_fd, BUFSIZE);
        } while(!csi_cnt_bytes);

        record_status(buf_addr, csi_cnt_bytes, csi_status);

        /* wait until is ready to write */
        while(!ready_to_write);

        buf_len = csi_status->buf_len;
        fwrite(&buf_len, 1, 2, write_file);
        fwrite(buf_addr, 1, buf_len, write_file);
    }

    close_csi_device(csi_device_fd);
    free(csi_status);
}

void *files_cleaner(void *vargp) {
    char files_dir[512];
    sprintf(files_dir, "%s/outputs", get_selfpath());

    // Create output directory if not exists
    struct stat st = {0};
    if (stat(files_dir, &st) == -1) {
        mkdir(files_dir, 0700);
    }

    // Clean output directory;
    char rm_command[512];
    sprintf(rm_command, "rm %s/*", files_dir);
    system(rm_command);

    ready_to_init = TRUE;
    char file_name[512];
    while(TRUE) {
        sprintf(file_name, "%s/%d", files_dir, (int)time(NULL)-(MAX_FILES*FILE_TIME_SEC));
        remove(file_name);
        sleep(1);
    }
}

void *file_manager(void *vargp) {
    char file_name[512];
    char files_dir[512];
    sprintf(files_dir, "%s/outputs", get_selfpath());

    /* wait until ready to init */
    while(!ready_to_init);

    while(TRUE) {
        sprintf(file_name, "%s/%d", files_dir, (int)time(NULL));
        write_file = fopen(file_name,"w");
        if (!write_file) {
            printf("Fail to open <output_file>, are you root?\n");
            fclose(write_file);
            exit(0);
        }

        ready_to_write = TRUE;
        sleep(FILE_TIME_SEC);

        /* close file and add to the not recovered array */
        ready_to_write = FALSE;
        fclose(write_file);
        strcpy(stored_files[file_index%MAX_FILES], file_name);
        file_index++;
    }
}

char *get_selfpath() {
    char *path;
    char buff[512];
    path = (char*)malloc(sizeof(char) * 255);
    ssize_t len = readlink("/proc/self/exe", buff, sizeof(buff)-1);

    if (len != -1) {
      // -9 because we need to remove the executable name
      buff[len-9] = '\0';
      sprintf(path, "%s",buff);
      return path;
    }
}

void get_files(char** tmp_files) {
    int files_count = get_files_count();
    int i, real_index;
    int in_count = (file_index%MAX_FILES);
    int out_count = files_count - in_count;
    for(i = 0; i < files_count; i++) {
        real_index = (file_index > MAX_FILES) ? (((files_count-i) > in_count) ? (in_count+i) : (i-out_count)) : i;
        strcpy(tmp_files[i], stored_files[real_index]);
    }
    file_index = 0;
}

int get_files_count() {
    return (file_index >= MAX_FILES) ? MAX_FILES : file_index;
}

char **create_files_matrix() {
    int files_count = get_files_count();
    char **matrix = (char**)malloc(sizeof(char)*files_count*128);
    int i;
    for(i = 0; i < files_count; i++) {
        matrix[i] = (char *)malloc(sizeof(char)*512);
    }
    return matrix;
}
