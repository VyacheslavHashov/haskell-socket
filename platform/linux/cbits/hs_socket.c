#include <hs_socket.h>

int hs_get_last_socket_error() {
  return errno;
}

int hs_socket (int domain, int type, int protocol, int *err) {
#ifdef SOCK_NONBLOCK
  // On Linux, there is an optimized way to set a socket non-blocking
  int fd = socket(domain, type | SOCK_NONBLOCK, protocol);
  if (fd >= 0) {
    return fd;
  }
#else
  // This is the regular way via fcntl
  int fd = socket(domain, type, protocol);
  if (fd >= 0) {
    int flags = fcntl(fd, F_GETFL, 0);
    if (flags >= 0 && !fcntl(fd, F_SETFL, flags | O_NONBLOCK)) {
      return fd;
    } else {
      close(fd);
    }
  }
#endif
  *err = errno;
  return -1;
}

int hs_connect (int sockfd, const struct sockaddr *name, int namelen, int *err) {
  int i = connect(sockfd, name, namelen);
  *err = errno;
  return i;
}

int hs_bind    (int sockfd, const struct sockaddr *name, int namelen, int *err) {
  int i = bind(sockfd, name, namelen);
  *err = errno;
  return i;
}

int hs_listen (int sockfd, int backlog, int *err) {
  int i = listen(sockfd, backlog);
  *err = errno;
  return i;
}

int hs_accept (int sockfd, struct sockaddr *addr, int *addrlen, int *err) {
#ifdef SOCK_NONBLOCK
  // On Linux, there is an optimized way to set a socket non-blocking
  int fd = accept4(sockfd, addr, addrlen, SOCK_NONBLOCK);
  if (fd >= 0) {
    return fd;
  }
#else
  // This is the canonical way in absence of accept4
  int fd = accept(sockfd, addr, addrlen);
  if (fd >= 0) {
    int flags = fcntl(fd, F_GETFL, 0);
    if (flags >= 0 && !fcntl(fd, F_SETFL, flags | O_NONBLOCK)) {
      return fd;
    } else {
      close(fd);
    }
  }
#endif
  *err = errno;
  return -1;
}

int hs_close (int fd, int *err) {
  int i = close(fd);
  *err = errno;
  return i;
}
