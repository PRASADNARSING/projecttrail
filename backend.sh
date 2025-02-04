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

mkdir server
cd server
npm init -y
npm install express body-parser axios

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
  console.log(`Server is running on http://localhost:${port}`);
});
