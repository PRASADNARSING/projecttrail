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

# Script execution log
echo "Script started executing at: $TIMESTAMP" &>>$LOG_FILE_NAME

# Check if the script is run as root
CHECK_ROOT

# Database Setup for MongoDB
DB_NAME="touristPackages"
MONGO_URI="mongodb://localhost:27017/$DB_NAME"
echo "Connecting to MongoDB at $MONGO_URI"

# Install MongoDB if not installed
if ! command -v mongod &> /dev/null
then
    echo "MongoDB is not installed. Installing now..."
    sudo apt update
    sudo apt install -y mongodb
    sudo systemctl start mongodb
    sudo systemctl enable mongodb
    echo "MongoDB installation complete."
else
    echo "MongoDB is already installed."
fi

# Create database and collections
mongo <<EOF
use $DB_NAME;
db.createCollection("users");
db.createCollection("travelPackages");
echo "Database and collections created."
EOF
