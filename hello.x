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
