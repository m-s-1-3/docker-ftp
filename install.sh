#!/bin/bash -e

usage() {
    echo -ne "\n>>> Usage: $0 [ -d DIRECTORY ] [ -u USERNAME ] [ -p PASSWORD ] [ -i UID ]\n" 1>&2
}
exit_error() {
    if [ "$1" == "1" ]; then
        usage
    fi;
    exit 1
}

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root user!"
   exit 1
fi

if [[ -z $(which docker) || -z $(docker --version) ]]; then
   echo "docker is not installed. Run 'sudo apt install docker.io'" 1>&2
   exit_error 1
fi

while getopts ":d:u:p:i:" option
do
    case "${option}" in
        d)
	  FTP_DIR=${OPTARG}
	  ;;
        u)
	  FTP_USER=${OPTARG}
	  ;;
        p)
	  FTP_PASS=${OPTARG}
	  ;;
  	i)
	  FTP_UID=${OPTARG}
  	  ;;
	\? )
	  echo "Invalid option: $OPTARG" 1>&2
	  exit_error 1
	  ;;
    	: )
	  echo "Invalid option: $OPTARG requires an argument" 1>&2
	  exit_error 1
	  ;;
    esac
done

if [ "$#" -ne "8" ]; then
    echo  "Error: 4 parameters are required and cannot be empty!" 1>&2;
    exit_error
fi;

mkdir -m 775 -p ${FTP_DIR}
chown -R ${FTP_UID}:${FTP_UID} ${FTP_DIR}

cp docker-ftp.service /etc/systemd/system/docker-ftp.service

FTP_PASS_NCRYPT=`echo -n "${FTP_PASS}" | docker run -i --rm atmoz/makepasswd --crypt-md5 --clearfrom=-`
FTP_PASS_NCRYPT=${FTP_PASS_NCRYPT/${FTP_PASS}   /}

sed -i "s|{{FTP_DIR}}|${FTP_DIR}|g" /etc/systemd/system/docker-ftp.service
sed -i "s|{{FTP_USER}}|${FTP_USER}|g" /etc/systemd/system/docker-ftp.service
sed -i "s|{{FTP_PASS}}|${FTP_PASS_NCRYPT}|g" /etc/systemd/system/docker-ftp.service
sed -i "s|{{FTP_UID}}|${FTP_UID}|g" /etc/systemd/system/docker-ftp.service

systemctl enable docker-ftp.service
