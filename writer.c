#include <unistd.h>
#include <stdio.h>
#include <sys/syscall.h>
#include <sys/shm.h>
#include <sys/ipc.h>
#include <sys/types.h>
#include "buffer.h"

forth_input_buffer_t *buf;
key_t key;
int shm_id;

void* write_stdin() {
   for ( ; ; ) {
      while (buf->unread) {
         write(1, buf->read_pos++, 1);
         buf->unread--;
//         write(1,"-",1);
         usleep(200000);
      }
      buf->read_pos = buf->start;
      usleep(1000000);
   }
}

int main( int argc, char **argv) {
   key = ftok("writer.c",'F');   
   shm_id = shmget(key, 1024, IPC_CREAT | 0666);
   buf = (forth_input_buffer_t *)shmat(shm_id,NULL,0);
   buf->unread=0;
   buf->read_pos=buf->start;
   write_stdin();
   return 0;
}
