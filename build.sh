#!/bin/sh
BASE=$(pwd)


# pull submodules
git submodule init
git submodule update --recursive


# Get UTHASH for Smockron
git submodule init ${BASE}/pkgs/smockron
git submodule update --recursive ${BASE}/pkgs/smockron


# Mac OS X check
if [ $OSTYPE == "darwin13" ]; then
    #statements
    export FLAGS="--with-cc-opt='-Wno-deprecated-declarations'"
fi

# Check if zeromq is installed
if [[ -n $(ldconfig -p |grep zmq.so.3)]]; then
    yum remove zeromq zeromq-devel
    wget http://download.zeromq.org/zeromq-3.2.2.tar.gz
    tar zxvf zeromq-3.2.2.tar.gz && cd zeromq-3.2.2
    ./configure
    make && make install
    cd ..
    rm -rf zeromq*
fi

# Install required packages
yum install pcre-devel openssl-devel


cd src/
./configure \
    --sbin-path=/usr/sbin/nginx
    --conf-path=/etc/nginx/nginx.conf \
    --error-log-path=/var/log/nginx/error.log \
    --http-log-path=/var/log/nginx/access.log \
    --pid-path=/var/run/nginx.pid \
    --lock-path=/var/lock/nginx.lock \
    --with-http_dav_module \
    --http-client-body-temp-path=/var/tmp/nginx/body \
    --http-proxy-temp-path=/var/tmp/nginx/proxy \
    --http-fastcgi-temp-path=/var/tmp/nginx/fastcgi \
    --with-http_stub_status_module \
    --with-debug \
    --with-http_ssl_module \
    --with-pcre \
    --with-ipv6 \
    --add-module=${BASE}/pkgs/headers-more-nginx-module/ \
    --add-module=${BASE}/pkgs/smockron/nginx/ \
    --add-module=${BASE}/pkgs/requestid/ \
    ${FLAGS}

make
sudo make install