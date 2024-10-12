#!/bin/bash

# Wait for MongoDB to be available
until nc -z -v -w30 mongo 27017
do
  echo "Waiting for MongoDB database connection..."
  sleep 5
done

echo "MongoDB is up and running. Proceeding with the Deadline Repository installation."

# Install Deadline Repository non-interactively
/tmp/deadline-repo-installer.run --mode unattended --dbtype db \
    --dbhost mongo --dbport 27017 --dbuser admin --dbpassword password

# Start the Deadline Repository service
/etc/init.d/deadline-repository start

# Keep the container running
tail -f /dev/null
