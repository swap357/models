RUN apt-get update && \
  apt-get install -y software-properties-common
RUN apt-get update && \
  add-apt-repository -y ppa:ubuntu-toolchain-r/test && \
  apt-get install -y gcc-8 g++-8 && \
  update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-8 8 && \
  update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-8 8
