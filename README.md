PRC 프로토콜을 이용해서 ‘Hello World~!’를 원격 프로세스로부터 수신받아 출력하는 C 프로그램을 만드는 예제입니다. 최신 LTS에서 동작하지 않아 공유차 작성했습니다.

# 프로토콜 정의

```c
/* hello.x */

typedef struct str_s str_t;
struct str_s {
  char buf<>;
};

program HELLOPROG {
  version HELLOVERS {
    str_t HELLO_WORLD(void) = 0;
  } = 1;
} = 200001;
```

정의된 프로토콜 기반으로 필요한 샘플 코드 생성과
Ubuntu 22.04.04 LTS에서 컴파일 될 수 있도록 Makefile 수정

```bash
# opt '-a': generate all files, including samples
$ rpcgen -a hello.x

$ ll
total 32K
-rw-rw-r-- 1 ss0 ss0  796  2월 25 17:59 hello_client.c
-rw-rw-r-- 1 ss0 ss0  551  2월 25 17:59 hello_clnt.c
-rw-rw-r-- 1 ss0 ss0 1.1K  2월 25 17:59 hello.h
-rw-rw-r-- 1 ss0 ss0  318  2월 25 17:59 hello_server.c
-rw-rw-r-- 1 ss0 ss0 2.0K  2월 25 17:59 hello_svc.c
-rw-rw-r-- 1 ss0 ss0  189  2월 25 17:41 hello.x
-rw-rw-r-- 1 ss0 ss0  468  2월 25 17:59 hello_xdr.c
-rw-rw-r-- 1 ss0 ss0 1.1K  2월 25 17:59 Makefile.hello

# 최신 우분투의 경우 tirpc로 이관되어 해당 헤더를 찾을 수 없기 때문에 Makefile 변경이 필요
# $ make -f Makefile.hello
# cc -g    -c -o hello_clnt.o hello_clnt.c
# In file included from hello_clnt.c:7:
# hello.h:9:10: fatal error: rpc/rpc.h: No such file or directory
#     9 | #include <rpc/rpc.h>
#       |          ^~~~~~~~~~~
# compilation terminated.
# make: *** [<builtin>: hello_clnt.o] Error 1

# add include path, library
$ sed -i 's/CFLAGS += -g/CFLAGS += -g -I\/usr\/include\/tirpc/g' Makefile.hello
$ sed -i 's/LDLIBS += -lnsl/LDLIBS += -ltirpc/g' Makefile.hello

# Test make
$ make -f Makefile.hello
cc -g -I/usr/include/tirpc    -c -o hello_clnt.o hello_clnt.c
cc -g -I/usr/include/tirpc    -c -o hello_client.o hello_client.c
cc -g -I/usr/include/tirpc    -c -o hello_xdr.o hello_xdr.c
cc -g -I/usr/include/tirpc     -o hello_client  hello_clnt.o hello_client.o hello_xdr.o -ltirpc
cc -g -I/usr/include/tirpc    -c -o hello_svc.o hello_svc.c
cc -g -I/usr/include/tirpc    -c -o hello_server.o hello_server.c
cc -g -I/usr/include/tirpc     -o hello_server  hello_svc.o hello_server.o hello_xdr.o -ltirpc
```

# 서버 함수 구현 및 실행

```c
/* hello_server.c */
#include "hello.h"

str_t *hello_world_1_svc(void *argp, struct svc_req *rqstp) {
  static str_t result;
  const char str[] = "Hello, world!";

  result.buf.buf_len = strlen(str);
  result.buf.buf_val = strdup(str);

  printf("server: %s\n", result.buf.buf_val);

  return &result;
}

# Run Server
$ ./hello_server

$ rpcinfo
    200001    1    udp       0.0.0.0.207.237        -          1000
    200001    1    tcp       0.0.0.0.233.37         -          1000
```

# 클라이언트 함수 구현 및 테스트

```c
/* hello_client.c */
void helloprog_1(char *host) {
  CLIENT *clnt;
  str_t *result_1;
  char *hello_world_1_arg;

#ifndef DEBUG
  clnt = clnt_create(host, HELLOPROG, HELLOVERS, "udp");
  if (clnt == NULL) {
    clnt_pcreateerror(host);
    exit(1);
  }
#endif /* DEBUG */

  result_1 = hello_world_1((void *)&hello_world_1_arg, clnt);
  if (result_1 == (str_t *)NULL) {
    clnt_perror(clnt, "call failed");
  }

  printf("client: %s\n", result_1->buf.buf_val);

#ifndef DEBUG
  clnt_destroy(clnt);
#endif /* DEBUG */
}

$ ./hello_client localhost
client: Hello, world!
# server: Hello, world!
```
