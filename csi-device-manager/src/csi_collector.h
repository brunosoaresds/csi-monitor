/*
 * =====================================================================================
 *       Filename:  csi_collector.h
 *
 *    Description:  Collects CSI data from device and stores it in files.
 *        Version:  1.0
 *
 *         Author:  Bruno Soares da Silva
 *         Email :  <brunodasilva@inf.ufg.br>
 *   Organization:  LABORA - Universidade Federal de Goiás (UFG) - Brazil
 *
 *   Copyright (c)  LABORA - Universidade Federal de Goiás (UFG) - Brazil
 * =====================================================================================
 */
#define TRUE 1
#define FALSE 0

void *collect_csi_data(void *vargp);
void *files_cleaner(void *vargp);
void *file_manager(void *vargp);
char *get_selfpath();
void get_files(char** tmp_files);
int get_files_count();
char **create_files_matrix();