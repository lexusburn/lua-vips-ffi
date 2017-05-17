# setup for ubuntu 17.04

Add packages

	sudo apt-get install luajit luarocks libcurl4-openssl-dev 

Configure `luarocks` for a local tree

	luarocks help path

add

	eval `luarocks path`

to `~/.bashrc`

# install luarocks plugins

I'm not sure we need these. Are they for the nginx stuff?

	luarocks install --local magick 
	luarocks install --local Lua-cURL --server=https://rocks.moonscript.org/dev CURL_INCDIR=/usr/include/x86_64-linux-gnu
	luarocks install --local luafilesystem 
	luarocks install --local lua-path 
	luarocks install --local xml 
	luarocks install --local https://raw.githubusercontent.com/phpb-com/neturl/master/rockspec/net-url-scm-1.rockspec

# test

Run the test script with:

	luajit vips_script.lua

# links

	http://luajit.org/ext_ffi_api.html
	http://luajit.org/ext_ffi_semantics.html
