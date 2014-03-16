#!/bin/sh
BASE=$(pwd)


# Flush log
echo "" > build.log

# pull submodules
echo "!!! Checking out submodules"
git submodule init  >> build.log 2>&1
git submodule update --recursive  >> build.log 2>&1


# Get UTHASH for Smockron
git submodule init ${BASE}/pkgs/smockron  >> build.log 2>&1
git submodule update --recursive ${BASE}/pkgs/smockron  >> build.log 2>&1

echo "!!! Probing environment"
# Mac OS X check
if [ $OSTYPE == "darwin13" ]; then

    echo "!!! Building for OS X"
    # Fix deprecated md5 features
    export FLAGS="--with-cc-opt='-Wno-deprecated-declarations'"

elif [ $OSTYPE == "linux-gnu" ]; then
    
    echo "!!! Building for Linux"
    # Check if zeromq is installed
    if [[ -n $(ldconfig -p |grep zmq.so.3) ]]; then
        yum remove zeromq zeromq-devel
        wget http://download.zeromq.org/zeromq-3.2.2.tar.gz  >> build.log 2>&1
        tar zxvf zeromq-3.2.2.tar.gz  >> build.log 2>&1 && cd zeromq-3.2.2  >> build.log 2>&1
        ./configure  >> build.log 2>&1
        make  >> build.log 2>&1 && make install >> build.log 2>&1
        cd ..
        rm -rf zeromq*
    fi

    # Install required packages
    yum install pcre-devel openssl-devel

fi


# Enter into nginx source dir
cd src/

# Apply NGINX Patch
echo "Patching Rocketbox..."
patch -p1 -s < ../patches/001_nginx_ver.patch >> build.log

# Configure
echo "Configuring Rocketbox..."
./configure \
    --sbin-path=/usr/sbin/nginx \
    --conf-path=/etc/nginx/nginx.conf \
    --error-log-path=/var/log/nginx/error.log \
    --http-log-path=/var/log/nginx/access.log \
    --pid-path=/var/run/nginx.pid \
    --lock-path=/var/lock/nginx.lock \
    --http-client-body-temp-path=/var/tmp/nginx/body \
    --http-proxy-temp-path=/var/tmp/nginx/proxy \
    --http-fastcgi-temp-path=/var/tmp/nginx/fastcgi \
    --with-debug \
    --with-http_ssl_module \
    --without-http_autoindex_module \
    --without-http_ssi_module \
    --with-pcre \
    --with-ipv6 \
    --add-module=${BASE}/pkgs/headers-more-nginx-module/ \
    --add-module=${BASE}/pkgs/smockron/nginx/ \
    --add-module=${BASE}/pkgs/requestid/ \
    ${FLAGS} >> build.log 2>&1


# Build and install
echo "Building Rocketbox..." 
make >> build.log 2>&1 && echo "Installing Rocketbox..." && sudo make install >> build.log 2>&1

# Test
NGINX_TEST=$(sudo /usr/sbin/nginx -t >> build.log 2>&1)
if [[ $? -eq 0 ]]; then
    echo "Rocketbox installed successfully"
else
    echo "There was an issue installing rocketbox"
fi
