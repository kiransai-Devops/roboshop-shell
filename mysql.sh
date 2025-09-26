#!/bin/bash


USER_ID=$(id -u)
R="/e[31m"
G="/e[32m"
Y="/e[33m"
N="/e[0m"


LOGS_FOLDER="/var/log/roboshop-shell"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
START_TIME=$(date +%s)
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

dnf install mysql-server -y &>>$LOG_FILE
VALIDATE $? "install mysql"
systemctl enable mysqld &>>$LOG_FILE
VALIDATE $? "enable mysql"
systemctl start mysqld  &>>$LOG_FILE
VALIDATE $? "start mysql"
mysql_secure_installation --set-root-pass RoboShop@1&>>$LOG_FILE
VALIDATE $? "set user"

END_TIME=$(date +%s)
TOTAL_TIME=$(($END_TIME - $START_TIME))
echo -e "scrpit exicuted in: $Y $TOTAL_TIME seconds $N"