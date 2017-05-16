# Pull base image.
FROM openresty/openresty:xenial

# install ubuntu packages
RUN apt-get update && apt-get install -y \
    luarocks \
    luajit \
    libmagickwand-dev \
    libgraphicsmagick1-dev \
    curl \
    wget \
    libcurl4-openssl-dev \
    git \
    autoconf \
    automake \
    libtool \
    swig \
    gtk-doc-tools \
    libglib2.0-dev \
    build-essential \
    libxml2-dev \
    libfftw3-dev \
    libopenexr-dev \
    liborc-0.4-0 \
    gobject-introspection \
    libgsf-1-dev

# build vips from sources because package version is too old
RUN mkdir -p /etc/vips && \
    cd /etc/vips && \
    wget "https://github.com/jcupitt/libvips/releases/download/v8.5.5/vips-8.5.5.tar.gz" && \
    tar xf vips-8.5.5.tar.gz && \
    cd vips-8.5.5 && \
    ./configure && \
    make && \
    make install && \
    echo "/usr/local/lib" > /etc/ld.so.conf.d/usrlocal.conf && \
    ldconfig -v

# install luarocks plugins
RUN luarocks install magick && \
    luarocks install Lua-cURL --server=https://rocks.moonscript.org/dev && \
    luarocks install luafilesystem && \
    luarocks install lua-path && \
    luarocks install xml && \
    luarocks install https://raw.githubusercontent.com/phpb-com/neturl/master/rockspec/net-url-scm-1.rockspec

# copy nginx config
COPY etc/nginx/nginx.conf /usr/local/openresty/nginx/conf/
COPY etc/nginx/lua /usr/local/openresty/nginx/lua
COPY data /data


EXPOSE 80

# Add additional binaries into PATH for convenience
ENV PATH=$PATH:/usr/local/openresty/luajit/bin/:/usr/local/openresty/nginx/sbin/:/usr/local/openresty/bin/

ENTRYPOINT ["/usr/local/openresty/bin/openresty", "-g", "daemon off;"]
#ENTRYPOINT ["/bin/bash"]


