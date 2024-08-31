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

void* read_stdin() {
   int len;
   for ( ; ; ) {
      if ( buf->unread == 0 ) {
         write(1,">",1);
         len = read( 0, &buf->start, 256 );
         buf->unread = len;
         usleep(200000);
      }
      usleep(200000);
   }
}


int main( int argc, char **argv) {
   key = ftok("writer.c",'F');   
   shm_id = shmget(key, 1024, 0666);
   buf = shmat(shm_id,NULL,0);
   read_stdin();
   return 0;
}
