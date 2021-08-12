#ifndef _FILE_UTIL_H
#define _FILE_UTIL_H

/*
 * Write an integer to a file
 */
int write_file_int(const char *file, int number);

/*
 * Write a string to a file
 */
int write_file_str(const char *file, const char *str);

/*
 * Return if the path exists (file / dir)
 */
int path_exists(const char *path);

#endif
