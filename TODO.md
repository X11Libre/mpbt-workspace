TODO
====

- [ ] set up git-autopick (xorg backports)
- [ ] add pkg-config checks for OS-installed packages
- [ ] github CI: check apt-caching: the netbsd job still downloading lots of deb packages
- [ ] github CI: check apt-caching: the dragonfly job still downloading lots of deb packages
- [ ] github CI: check apt-caching: the freebsd job still downloading lots of deb packages
- [ ] github CI: alpine job runs in container --> doesn't need to wait for ubuntu-pkg job
- [ ] github CI: PRs always trigger two duplicate pipelines (even when pushing into existing one)
- [ ] add script for setting up git object sharing between the xserver repos
- [ ] add automatic build of a cygwin repo
- [ ] check whether it's possible to run a real Xserver (xfree86 or Xfbdev) within the github CI.
- [ ] add agent helper scripts for github api access (eg log retrieval) and authorize them (no more manual confirmation)

reviews:
--------

