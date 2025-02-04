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

# Start script execution
echo "Starting frontend deployment..." | tee -a "$LOG_FILE_NAME"

# Check if the user is root
CHECK_ROOT

# Step 1: Install Node.js and npm (if not installed)
echo "Checking if Node.js is installed..." | tee -a "$LOG_FILE_NAME"
if ! command -v node &>/dev/null
then
    echo "Node.js is not installed. Installing now..." | tee -a "$LOG_FILE_NAME"
    curl -sL https://rpm.nodesource.com/setup_16.x | sudo -E bash -
    sudo yum install -y nodejs
    VALIDATE $? "Node.js installation"
else
    echo "Node.js is already installed." | tee -a "$LOG_FILE_NAME"
fi

# Step 2: Install create-react-app globally (if not installed)
echo "Checking if create-react-app is installed..." | tee -a "$LOG_FILE_NAME"
if ! command -v create-react-app &>/dev/null
then
    echo "create-react-app is not installed. Installing now..." | tee -a "$LOG_FILE_NAME"
    sudo npm install -g create-react-app
    VALIDATE $? "create-react-app installation"
else
    echo "create-react-app is already installed." | tee -a "$LOG_FILE_NAME"
fi

# Step 3: Create React app
echo "Creating React app..." | tee -a "$LOG_FILE_NAME"
npx create-react-app expense-frontend
VALIDATE $? "React app creation"

# Step 4: Build the React app
echo "Building React app..." | tee -a "$LOG_FILE_NAME"
cd expense-frontend
npm run build
VALIDATE $? "React app build"

# Step 5: Install Nginx (if not installed)
echo "Checking if Nginx is installed..." | tee -a "$LOG_FILE_NAME"
if ! command -v nginx &>/dev/null
then
    echo "Nginx is not installed. Installing now..." | tee -a "$LOG_FILE_NAME"
    sudo yum install -y nginx
    VALIDATE $? "Nginx installation"
else
    echo "Nginx is already installed." | tee -a "$LOG_FILE_NAME"
fi

# Step 6: Configure Nginx to serve React app
echo "Configuring Nginx to serve the React app..." | tee -a "$LOG_FILE_NAME"
sudo cp -r build/* /usr/share/nginx/html/
VALIDATE $? "Copying build files to Nginx"

# Step 7: Restart Nginx
echo "Restarting Nginx..." | tee -a "$LOG_FILE_NAME"
sudo systemctl restart nginx
VALIDATE $? "Restarting Nginx"

# Final message
echo -e "$G Frontend deployment completed successfully! $N" | tee -a "$LOG_FILE_NAME"
