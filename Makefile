all:
	cake build 
	cd ../../application/ && make install > /dev/zero
