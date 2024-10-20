#!/bin/bash

# Function to print a section header
print_header() {
  echo
  echo "=========================================="
  echo "$1"
  echo "=========================================="
  echo
}

# Update package manager and install basic dependencies
print_header "Updating system and installing required packages"
sudo apt update && sudo apt upgrade -y
sudo apt install curl wget git openjdk-17-jdk maven nodejs npm -y

# Install Kotlin and SDKMAN for backend setup
print_header "Installing Kotlin and SDKMAN"
curl -s "https://get.sdkman.io" | bash
source "$HOME/.sdkman/bin/sdkman-init.sh"
sdk install kotlin
sdk install gradle

# Install PostgreSQL or MySQL for the backend database
DB_CHOICE="postgresql"
print_header "Installing $DB_CHOICE"
if [ "$DB_CHOICE" == "postgresql" ]; then
  sudo apt install postgresql postgresql-contrib -y
  sudo systemctl start postgresql
  sudo -u postgres psql -c "CREATE USER springboot_user WITH PASSWORD 'password';"
  sudo -u postgres createdb springboot_db -O springboot_user
else
  sudo apt install mysql-server -y
  sudo systemctl start mysql
  sudo mysql -u root -e "CREATE DATABASE springboot_db;"
  sudo mysql -u root -e "CREATE USER 'springboot_user'@'localhost' IDENTIFIED BY 'password';"
  sudo mysql -u root -e "GRANT ALL PRIVILEGES ON springboot_db.* TO 'springboot_user'@'localhost';"
  sudo mysql -u root -e "FLUSH PRIVILEGES;"
fi

# Clone backend Spring Boot project
print_header "Setting up Spring Boot backend"
git clone https://github.com/allyelvis/springboot-invoice-app.git
cd springboot-invoice-app
./mvnw clean install

# Run the Spring Boot application
print_header "Running Spring Boot backend"
./mvnw spring-boot:run &

# Install Android SDK and related tools for frontend
print_header "Installing Android SDK"
sudo apt install android-sdk -y
wget https://dl.google.com/android/repository/commandlinetools-linux-8092744_latest.zip -O commandlinetools.zip
unzip commandlinetools.zip -d $HOME/android-sdk/cmdline-tools
mv $HOME/android-sdk/cmdline-tools/cmdline-tools $HOME/android-sdk/cmdline-tools/latest
rm commandlinetools.zip

export ANDROID_HOME=$HOME/android-sdk
export PATH=$ANDROID_HOME/cmdline-tools/latest/bin:$PATH
export PATH=$ANDROID_HOME/platform-tools:$PATH
yes | sdkmanager --licenses
sdkmanager "platform-tools" "platforms;android-30" "build-tools;30.0.3"

# Set up Android Studio project (requires manual setup through IDE)
print_header "Setting up Android Studio project"
mkdir -p ~/AndroidStudioProjects/InvoiceApp
cd ~/AndroidStudioProjects/InvoiceApp
git clone https://github.com/your-repo/android-invoice-app.git

# Install Node.js and required packages for frontend integration
print_header "Installing Node.js packages for Android project"
cd android-invoice-app
npm install

# Install Retrofit, Room, and other libraries
print_header "Adding Retrofit, Room, and necessary libraries"
echo "
dependencies {
    implementation 'com.squareup.retrofit2:retrofit:2.9.0'
    implementation 'com.squareup.retrofit2:converter-gson:2.9.0'
    implementation 'androidx.room:room-runtime:2.4.0'
    kapt 'androidx.room:room-compiler:2.4.0'
    implementation 'com.squareup.okhttp3:okhttp:4.9.1'
}
" >> app/build.gradle

# Install Docker (optional if you want to containerize the backend)
print_header "Installing Docker"
sudo apt install docker.io -y
sudo systemctl start docker
sudo systemctl enable docker

# Create Dockerfile for backend
print_header "Setting up Docker container for Spring Boot"
cat <<EOL > Dockerfile
# Use an official OpenJDK runtime as a parent image
FROM openjdk:17-jdk-slim

# Set the working directory in the container
WORKDIR /app

# Copy the project jar file into the container
COPY target/springboot-invoice-app-0.0.1-SNAPSHOT.jar /app/invoice-app.jar

# Run the jar file
CMD ["java", "-jar", "/app/invoice-app.jar"]
EOL

# Build and run Docker container for the backend
docker build -t invoice-app .
docker run -p 8080:8080 invoice-app &

# Output setup completion message
print_header "Setup Completed Successfully!"
echo "Spring Boot backend running on http://localhost:8080"
echo "Android project ready at ~/AndroidStudioProjects/InvoiceApp"
echo "You can now open Android Studio and work on the frontend."
