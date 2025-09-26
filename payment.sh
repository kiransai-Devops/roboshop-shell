#!/bin/bash

USER_ID=$(id -u)
R="/e[31m"
G="/e[32m"
Y="/e[33m"
N="/e[0m"

LOGS_FOLDER="/var/log/roboshop-shell"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
SCRIPT_DIR=$PWD
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
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

dnf install python3 gcc python3-devel -y &>>$LOG_FILE

id  roboshop &>>$LOG_FILE

if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    VALIDATE $? "creating user"
else
    echo -e "user alredy exit ... $Y SKIPPING $N"
fi

mkdir -p /app 
VALIDATE $? "creating directory"

curl -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip &>>$LOG_FILE
VALIDATE $? "temperory" 

cd /app
VALIDATE $? "change the dir"

rm -rf /app/* &>>$LOG_FILE
VALIDATE $? "remove existing code" 

unzip /tmp/payment.zip &>>$LOG_FILE
VALIDATE $? "unzip"
pip3 install -r requirements.txt &>>$LOG_FILE

cp $SCRIPT_DIR /payment.service /etc/systemd/system/payment.service  &>>$LOG_FILE
VALIDATE $? "payment service"
systemctl daemon-reload
VALIDATE $? "reload"
systemctl enable payment &>>$LOG_FILE
VALIDATE $? "enable"
systemctl start payment &>>$LOG_FILE
VALIDATE $? "start"


