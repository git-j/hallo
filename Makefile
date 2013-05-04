all:
	PATH=${PATH}:./node_modules/.bin/ cake  build 
	cd ../../application/ && make install > /dev/zero
