#!/bin/bash

USERID=$(id -u)
R="\e[31m"  # Red for errors
G="\e[32m"  # Green for success
Y="\e[33m"  # Yellow for warnings
N="\e[0m"   # Reset color

LOGS_FOLDER="/var/log/backend-logs"
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

# Install Node.js
if ! command -v node &> /dev/null
then
    echo "Node.js is not installed. Installing now..." | tee -a "$LOG_FILE_NAME"
    # Remove existing Node.js (if any)
    sudo yum remove -y nodejs &>> "$LOG_FILE_NAME"
    # Download and run the NodeSource setup script
    curl -fsSL https://rpm.nodesource.com/setup_16.x | sudo bash - &>> "$LOG_FILE_NAME"
    # Install Node.js
    sudo yum install -y nodejs &>> "$LOG_FILE_NAME"
    VALIDATE $? "Node.js installation"
else
    echo "Node.js is already installed." | tee -a "$LOG_FILE_NAME"
fi

# Install PM2 (Process Manager for Node.js)
if ! command -v pm2 &> /dev/null
then
    echo "PM2 is not installed. Installing now..." | tee -a "$LOG_FILE_NAME"
    sudo npm install -g pm2 &>> "$LOG_FILE_NAME"
    VALIDATE $? "PM2 installation"
else
    echo "PM2 is already installed." | tee -a "$LOG_FILE_NAME"
fi

# Create server directory
SERVER_DIR="/home/ec2-user/server"
if [ ! -d "$SERVER_DIR" ]; then
    echo "Creating server directory..." | tee -a "$LOG_FILE_NAME"
    mkdir -p "$SERVER_DIR"
    VALIDATE $? "Creating server directory"
else
    echo "Server directory already exists." | tee -a "$LOG_FILE_NAME"
fi

# Initialize Node.js project
echo "Initializing Node.js project..." | tee -a "$LOG_FILE_NAME"
cd "$SERVER_DIR"
npm init -y &>> "$LOG_FILE_NAME"
VALIDATE $? "Initializing Node.js project"

# Install dependencies
echo "Installing dependencies..." | tee -a "$LOG_FILE_NAME"
npm install express body-parser axios &>> "$LOG_FILE_NAME"
VALIDATE $? "Installing dependencies"

# Create server.js file
echo "Creating server.js file..." | tee -a "$LOG_FILE_NAME"
cat <<EOL > server.js
const express = require('express');
const bodyParser = require('body-parser');
const axios = require('axios');
const app = express();
const port = 5000;

app.use(bodyParser.json());

app.post('/get-suggestions', async (req, res) => {
  const { passportCountry, visaCountry, travelDate, returnDate, numPeople } = req.body;

  // Example Visa-Free logic
  const visaFreeCountries = ['Mexico', 'Singapore', 'Turkey'];

  // Example package suggestion (Replace with real API calls)
  const packages = [
    { country: 'Mexico', price: 500 },
    { country: 'Singapore', price: 600 },
    { country: 'Turkey', price: 700 }
  ];

  res.json({ visaFreeCountries, packages });
});

app.listen(port, () => {
  console.log(\`Server is running on http://localhost:\${port}\`);
});
EOL
VALIDATE $? "Creating server.js file"

# Start the server using PM2
echo "Starting the server using PM2..." | tee -a "$LOG_FILE_NAME"
pm2 start server.js --name "backend" &>> "$LOG_FILE_NAME"
VALIDATE $? "Starting server using PM2"

# Save PM2 process list
pm2 save &>> "$LOG_FILE_NAME"
VALIDATE $? "Saving PM2 process list"

# Set up PM2 to start on boot
echo "Setting up PM2 to start on boot..." | tee -a "$LOG_FILE_NAME"
pm2 startup &>> "$LOG_FILE_NAME"
VALIDATE $? "Setting up PM2 startup"

echo "Script execution completed at: $(date +%Y-%m-%d-%H-%M-%S)" | tee -a "$LOG_FILE_NAME"