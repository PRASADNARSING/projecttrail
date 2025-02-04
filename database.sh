#!/bin/bash

USERID=$(id -u)
R="\e[31m"  # Red for errors
G="\e[32m"  # Green for success
Y="\e[33m"  # Yellow for warnings
N="\e[0m"   # Reset color

LOGS_FOLDER="/var/log/expense-logs"
LOG_FILE=$(echo $0 | cut -d "." -f1 )
TIMESTAMP=$(date +%Y-%m-%d-%H-%M-%S)
LOG_FILE_NAME="$LOGS_FOLDER/$LOG_FILE-$TIMESTAMP.log"

# Create logs folder if it doesn't exist
if [ ! -d "$LOGS_FOLDER" ]; then
    mkdir -p "$LOGS_FOLDER"
    echo "Directory $LOGS_FOLDER created."
fi

VALIDATE(){
    if [ $1 -ne 0 ]
    then
        echo -e "$2 ... $R FAILURE $N" | tee -a "$LOG_FILE_NAME"
        exit 1
    else
        echo -e "$2 ... $G SUCCESS $N" | tee -a "$LOG_FILE_NAME"
    fi
}

CHECK_ROOT(){
    if [ $USERID -ne 0 ]
    then
        echo "ERROR:: You must have sudo access to execute this script" | tee -a "$LOG_FILE_NAME"
        exit 1 #other than 0
    fi
}

# Script execution log
echo "Script started executing at: $TIMESTAMP" | tee -a "$LOG_FILE_NAME"

# Check if the script is run as root
CHECK_ROOT

# Database Setup for MySQL
DB_NAME="touristPackages"
MYSQL_URI="mysql://localhost/$DB_NAME"
echo "Connecting to MySQL at $MYSQL_URI" | tee -a "$LOG_FILE_NAME"

# Install MySQL if not installed (Amazon Linux uses yum)
if ! command -v mysql &> /dev/null
then
    echo "MySQL is not installed. Installing now..." | tee -a "$LOG_FILE_NAME"
    
    sudo yum install -y mysql-server &>> "$LOG_FILE_NAME"
    VALIDATE $? "MySQL installation"
fi

# Ensure MySQL service is running
if ! systemctl is-active --quiet mysqld; then
    sudo systemctl start mysqld &>> "$LOG_FILE_NAME"
    VALIDATE $? "Starting MySQL service"
else
    echo "MySQL service is already running." | tee -a "$LOG_FILE_NAME"
fi

sudo systemctl enable mysqld &>> "$LOG_FILE_NAME"
VALIDATE $? "Enabling MySQL service"

# Check if MySQL root password is already set
if mysql -u root -e "SELECT 1" &>> "$LOG_FILE_NAME"; then
    echo "MySQL root password is already set." | tee -a "$LOG_FILE_NAME"
else
    # Set MySQL root password using ALTER USER command
    MYSQL_ROOT_PASS="Shashi@123!"
    echo "Setting MySQL root password..." | tee -a "$LOG_FILE_NAME"
    sudo mysql -u root <<EOF &>> "$LOG_FILE_NAME"
    ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '$MYSQL_ROOT_PASS';
    FLUSH PRIVILEGES;
EOF
    VALIDATE $? "Setting MySQL root password"
fi

# Create database and tables
mysql -u root -p"$MYSQL_ROOT_PASS" <<EOF &>> "$LOG_FILE_NAME"
CREATE DATABASE IF NOT EXISTS $DB_NAME;
USE $DB_NAME;

-- Create users table
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create travelPackages table
CREATE TABLE IF NOT EXISTS travelPackages (
    id INT AUTO_INCREMENT PRIMARY KEY,
    package_name VARCHAR(255) NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Verify Database and Tables
SHOW TABLES;
EOF

VALIDATE $? "Creating database and tables"