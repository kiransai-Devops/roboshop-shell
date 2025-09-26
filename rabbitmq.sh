#!/bin/bash


USER_ID=$(id -u)
R="/e[31m"
G="/e[32m"
Y="/e[33m"
N="/e[0m"


LOGS_FOLDER="/var/log/roboshop-shell"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
START_TIME=$(date +%s)
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

cp $SCRIPT_DIR/rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo &>>$LOG_FILE
VALIDATE $? "rabbit repo"
dnf install rabbitmq-server -y &>>$LOG_FILE
VALIDATE $? "install rabbit"
systemctl enable rabbitmq-server &>>$LOG_FILE
VALIDATE $? "enable rabbit"
systemctl start rabbitmq-server &>>$LOG_FILE
VALIDATE $? "start rabbit"
rabbitmqctl add_user roboshop roboshop123 &>>$LOG_FILE
VALIDATE $? "add user"
rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*" &>>$LOG_FILE
VALIDATE $? "set permission"

END_TIME=$(date +%s)
TOTAL_TIME=$(($END_TIME - $START_TIME))
echo -e "scrpit exicuted in: $Y $TOTAL_TIME seconds $N"