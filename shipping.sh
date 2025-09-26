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
MYSQL_HOST=mysql.kidevops.shop
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

dnf install maven -y &>>$LOG_FILE

id  roboshop &>>$LOG_FILE

if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    VALIDATE $? "creating user"
else
    echo -e "user alredy exit ... $Y SKIPPING $N"
fi

mkdir -p /app 
VALIDATE $? "creating directory"

curl -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>>$LOG_FILE
VALIDATE $? "temperory" 

cd /app
VALIDATE $? "change the dir"

rm -rf /app/* &>>$LOG_FILE
VALIDATE $? "remove existing code" 

unzip /tmp/shipping.zip &>>$LOG_FILE
VALIDATE $? "unzip"

mvn clean package 
VALIDATE $? "clean package"
mv target/shipping-1.0.jar shipping.jar &>>$LOG_FILE
VALIDATE $? "install"
cp $SCRIPT_DIR/shipping.service /etc/systemd/system/shipping.service  &>>$LOG_FILE
VALIDATE $? "shipping service"
systemctl daemon-reload
VALIDATE $? "reload"
systemctl enable shipping 
VALIDATE $? "enable"
systemctl start shipping
VALIDATE $? "start"

dnf install mysql -y 
mysql -h $MYSQL_HOST -uroot -pRoboShop@1 'use mysql' &>>$LOG_FILE
if [ $? -ne 0 ]; then
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/schema.sql &>>$LOG_FILE
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/app-user.sql &>>$LOG_FILE
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/master-data.sql &>>$LOG_FILE
else 
    echo -e "shipping data is alredy loaded ... $Y SKIPPING $N"
fi

systemctl restart shipping
