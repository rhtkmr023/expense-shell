#!/bin/bash/

LOGS_FOLDER="/var/log/expense"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
TIMESTAMP=$(date +%y-%m-%d-%H-%M-%S)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME-$TIMESTAMP.log"
mkdir -p $LOGS_FOLDER

USERID=$(id -u) #echo "User ID is: $USERID"
R="\e[31m"
G="\e[32m"
N="\e[0m"
Y="\e[33m"

CHECK_ROOT(){
    if [ $USERID -ne 0 ]
    then
        echo -e "$R Please run this script with root privileges $N" | tee -a $LOG_FILE
        exit 1
    fi
}

VALIDATE(){
    if [ $1 -ne 0 ]
    then
        echo -e "$2 is..$R FAILED $N" | tee -a $LOG_FILE
        exit 1
    else
        echo -e "$2 is..$G SUCCESS $N" | tee -a $LOG_FILE
    fi
}

echo "Script started executing at: $(date)" | tee -a $LOG_FILE

CHECK_ROOT

dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "Disable default nodejs"

dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "Enable nodejs: 20"

dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "Install nodejs"

id expense &>>$LOG_FILE
    if [ $? -ne 0 ]
    then
        echo -e "expense user not available.. $G Creating expense user $N"
        useradd expense &>>$LOG_FILE
        VALIDATE $? "creating expense user"
    else
        echo -e "expense user already availble.. $Y SKIPPING $N"
    fi

    mkdir -p /app #"-p" added for if /app folder exists folder shall not be added or else folder will be created.
    VALIDATE $? "creating /app folder"

    curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip &>>$LOG_FILE #Download the application code to created app directory.
    VALIDATE $? "Downloading Backend application code"

    cd /app
    rm -rf /app/* #removes the existing code to prevent code & program errors.
    unzip /tmp/backend.zip &>>$LOG_FILE
    VALIDATE $? "Extracting Backend application code"

    npm install &>>$LOG_FILE
    cp /home/ec2-user/expense-shell/backend.service /etc/systemd/system/backend.service

    #load the data before running backend

    dnf install mysql -y &>>$LOG_FILE
    VALIDATE $? "Installing MYSQL Client"

    mysql -h mysql.rohitdaws81s.shop -uroot -pExpenseApp@1 < /app/schema/backend.sql
    VALIDATE $? "Schema Loading is success"

    systemctl daemon-reload &>>$LOG_FILE
    VALIDATE $? "Daemon reload"

    systemctl enable backend &>>$LOG_FILE
    VALIDATE $? "Enabled Backend"

    systemctl restart backend &>>$LOG_FILE
    VALIDATE $? "Restarted Backend"

    
