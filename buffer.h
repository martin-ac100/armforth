typedef struct forth_input_buffer_t {
        int unread;
        char *read_pos;
        char start[256];
} forth_input_buffer_t;
