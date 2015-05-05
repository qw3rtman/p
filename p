#!/usr/bin/env bash

if [ "$1" == "default" ]; then
	rm -rf "/usr/local/p/versions/python/python"

	echo "Now using default Python."

	exit 0
fi

echo "Downloading..."

{
	wget -N --timestamping -O "/usr/local/p/versions/python/$1.tgz" "https://www.python.org/ftp/python/$1/Python-$1.tgz"
	tar xf "/usr/local/p/versions/python/$1.tgz" -C /usr/local/p/versions/python

	mv "/usr/local/p/versions/python/Python-$1" "/usr/local/p/versions/python/$1"
} &> /dev/null

if [ ! -f "/usr/local/p/versions/python/$1.tgz" ]; then
	echo "Unable to download Python $1!"

	exit 0
fi


echo "Compiling..."

{
	cd "/usr/local/p/versions/python/$1"
	./configure
	make
} &> /dev/null

if [ ! -f "/usr/local/p/versions/python/$1/python.exe" ]; then
	echo "Unable to compile Python $1!"

	exit 0
fi


echo "Swapping..."

{
	ln -sf "/usr/local/p/versions/python/$1/python.exe" "/usr/local/p/versions/python/python"
}

if [ ! -f "/usr/local/p/versions/python/python" ]; then
	echo "Unable to swap in new Python!"

	exit 0
fi

echo "Cleaning up..."

{
	rm -rf "/usr/local/p/versions/python/$1.tgz"
}

echo -e "\nNow using Python $1!"

PATH=/usr/local/p/versions/python:$PATH
