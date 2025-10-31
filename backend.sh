# #!/bin/bash

# USERID=$(id -u)
# R="\e[31m"
# G="\e[32m"
# Y="\e[33m"
# N="\e[0m"
# LOGS_FOLDER="/var/log/expense-logs"
# SCRIPT_NAME=$(echo $0 | cut -d "." -f1)

# LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
# SCRPT_DIR=$PWD

# mkdir -p $LOGS_FOLDER
# echo "Script started executing at: $(date)" | tee -a $LOG_FILE

# #check the user has root priveleges or not 
# if [ $USERID -ne 0 ]
# then 
#     echo -e "$R ERROR:: Please run this script with root access $N" | tee -a $LOG_FILE
#     exit 1 
# else    
#     echo "You are running with root access" | tee -a $LOG_FILE
# fi

# #validate functions takes input as exit status, what command they tried to install
# VALIDATE(){
#     if [ $1 -eq 0 ]
#     then 
#         echo -e "$2 is ... $G SUCCESS $N" | tee -a $LOG_FILE
#     else
#         echo -e "$2 is ... $R FAILURE $N" | tee -a $LOG_FILE
#         exit 1
#     fi
# }

# dnf module disable nodejs -y &>>$LOG_FILE
# VALIDATE $? "Disabling default nodejs"

# dnf module enable nodejs:20 -y &>>LOG_FILE
# VALIDATE $? "Enabling nodejs:20"

# dnf install nodejs -y &>>$LOG_FILE
# VALIDATE $? "Installing nodejs:20"

# id expense
# if [$? -ne 0 ]
# then 
#     useradd --system --home /app --shell /sbin/nologin --comment "expense user" expense &>>$LOG_FILE
#     VALIDATE $? "Creating expense user"
# else 
#     echo -e "System user expense already created ... $Y SKKIPPING $N"
# fi

# mkdir -p /app
# VALIDATE $? "Creating app directory"

# curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip &>>$LOG_FILE
# VALIDATE $? "Downloading expense-backend"

# rm -rf /app/*
# cd /app
# unzip /tmp/backend.zip &>>$LOG_FILE
# VALIDATE $? "unzipping backend"

# npm install &>>$LOG_FILE
# VALIDATE $? "Installing Dependencies"

# cp $SCRPT_DIR/backend.service /etc/systemd/system/backend.service
# VALIDATE $? "Copying backend service"

# #prepare mysql schema

# dnf install mysql -y &>>$LOG_FILE
# VALIDATE $? "Installing MySQL Client"

# mysql -h mysql.sree84s.site -uroot -pExpenseApp@1 < /app/schema/backend.sql &>>$LOG_FILE
# VALIDATE $? "Setting up the transactions schema and tables"

# systemctl daemon-reload &>>$LOG_FILE
# VALIDATE $? "Daemon Reload"

# systemctl enable backend &>>$LOG_FILE
# VALIDATE $? "Enabling backend"

# systemctl restart backend &>>$LOG_FILE
# VALIDATE $? "Starting Backend"

#!/bin/bash

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/expense-logs"
LOG_FILE=$(echo $0 | cut -d "." -f1 )
TIMESTAMP=$(date +%Y-%m-%d-%H-%M-%S)
LOG_FILE_NAME="$LOGS_FOLDER/$LOG_FILE-$TIMESTAMP.log"

VALIDATE(){
    if [ $1 -ne 0 ]
    then
        echo -e "$2 ... $R FAILURE $N"
        exit 1
    else
        echo -e "$2 ... $G SUCCESS $N"
    fi
}

CHECK_ROOT(){
    if [ $USERID -ne 0 ]
    then
        echo "ERROR:: You must have sudo access to execute this script"
        exit 1 #other than 0
    fi
}

echo "Script started executing at: $TIMESTAMP" &>>$LOG_FILE_NAME

CHECK_ROOT

dnf module disable nodejs -y &>>$LOG_FILE_NAME
VALIDATE $? "Disabling existing default NodeJS"

dnf module enable nodejs:20 -y &>>$LOG_FILE_NAME
VALIDATE $? "Enabling NodeJS 20"

dnf install nodejs -y &>>$LOG_FILE_NAME
VALIDATE $? "Installing NodeJS"

id expense &>>$LOG_FILE_NAME
if [ $? -ne 0 ]
then
    useradd expense &>>$LOG_FILE_NAME
    VALIDATE $? "Adding expense user"
else
    echo -e "expense user already exists ... $Y SKIPPING $N"
fi

mkdir -p /app &>>$LOG_FILE_NAME
VALIDATE $? "Creating app directory"

curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip &>>$LOG_FILE_NAME
VALIDATE $? "Downloading backend"

cd /app
rm -rf /app/*

unzip /tmp/backend.zip &>>$LOG_FILE_NAME
VALIDATE $? "unzip backend"

npm install &>>$LOG_FILE_NAME
VALIDATE $? "Installing dependencies"

cp /home/ec2-user/expense-shell/backend.service /etc/systemd/system/backend.service

# Prepare MySQL Schema

dnf install mysql -y &>>$LOG_FILE_NAME
VALIDATE $? "Installing MySQL Client"

mysql -h mysql.sree84s.site -uroot -pExpenseApp@1 < /app/schema/backend.sql &>>$LOG_FILE_NAME
VALIDATE $? "Setting up the transactions schema and tables"

systemctl daemon-reload &>>$LOG_FILE_NAME
VALIDATE $? "Daemon Reload"

systemctl enable backend &>>$LOG_FILE_NAME
VALIDATE $? "Enabling backend"

systemctl restart backend &>>$LOG_FILE_NAME
VALIDATE $? "Starting Backend"