#!/bin/bash

USER_ID=$(id -u)
R="/e[31m"
G="/e[32m"
Y="/e[33m"
N="/e[0m"

LOGS_FLODER="/var/log/roboshop-shell"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
LOG_FILE="$LOGS_FLODER/$SCRIPT_NAME.log"

mkdir -p $LOGS_FOLDER

echo "script started at: $(date)" | tee -a $LOG_FILE

if [ $USERID -ne 0 ]; then
    echo "ERROR:: please run this script with root privelege"
    exit 1
fi  

VALIDATE(){ 

  if [ $1 -ne 0 ]; then
      echo -e "$2 ... $R FAILURE $N" | tee -a $LOG_FILE
      exit 1
  else 
      echo -e "$2 ... $G SUCCESS $N" | tee -a $LOG_FILE
  fi
}  

cp mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "adding mongo repo" 
 
dnf install mongodb-org -y &>>$LOG_FILE
VALIDATE $? "install mongo"

systemctl enable mongod &>>$LOG_FILE
VALIDATE $? "enable mongo"

systemctl start mongod
VALIDATE $? "start mongo"