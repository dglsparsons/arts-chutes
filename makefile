all: 
	./cross-compile chutes_main.adb
	cp chutes_main  /tmp/tftpboot/world/program
	chmod a+r /tmp/tftpboot/world/program
