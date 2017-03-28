#define TRUE 1
#define FALSE 0

void *collect_csi_data(void *vargp);
void *files_cleaner(void *vargp);
void *file_manager(void *vargp);
char *get_selfpath();
void get_files(char** tmp_files);
int get_files_count();
char **create_files_matrix();