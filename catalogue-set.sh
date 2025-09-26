#!/bin/bash


USER_ID=$(id -u)
R="/e[31m"
G="/e[32m"
Y="/e[33m"
N="/e[0m"

set -euo pipefail

trap 'echo "there is an error in $LINENO, command is: $BASH_COMMAND"' ERR 

LOGS_FOLDER="/var/log/roboshop-shell"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
SCRIPT_DIR=$PWD
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
MONGODB_HOST=mongo.kidevops.shop
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

dnf module disable nodejs -y &>>$LOG_FILE

dnf module enable nodejs:20 -y &>>$LOG_FILE

dnf install nodejs -y &>>$LOG_FILE

id  roboshop &>>$LOG_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    
else
    echo -e "user alredy exit ... $Y SKIPPING $N"
fi

mkdir -p /app 

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$LOG_FILE

cd /app

rm -rf /app/*

unzip /tmp/catalogue.zip &>>$LOG_FILE

npm install &>>$LOG_FILE

cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service

systemctl daemon-reload

systemctl enable catalogue &>>$LOG_FILE

systemctl start catalogue

cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo

dnf install mongodb-mongosh -y &>>$LOG_FILE

INDEX=$(mongosh mongodb.daws86s.fun --quiet --eval "db.getMongo().getDBNames().indexOf('catalogue')")
if [ $INDEX -le 0 ]; then
    mongosh --host $MONGODB_HOST </app/db/master-data.js &>>$LOG_FILE
else 
    echo "catalogue product alredy loaded ... $Y SKIPPING $N"
fi
        
systemctl restart catalogue
