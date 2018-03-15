# Simple webserver written in gawk

A simple webserver written in GNU awk, that supports directory listing and download of files from the directory where it is launched.

It is born as an experiment, to demonstrate the power of the awk language.

# Usage

The script must be executed through a TCP wrapper.

I use this little shell script that requires socat:
```
while [ 1 ]; do
	socat TCP-LISTEN:8888,reuseaddr EXEC:"gawk -f webserver.awk"
	sleep 1
done 
```

You can then connect to the local 8888 port with your browser. Enjoy!
