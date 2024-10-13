# resource

https://thinkbox-installers.s3.us-west-2.amazonaws.com/Releases/Deadline/10.3/7_10.3.2.1/Deadline-10.3.2.1-linux-installers.tar

deadline-rcs-1        | Problem running post-install step. Installation may not complete correctly
deadline-rcs-1        |  Error: Could not connect to any of the specified Mongo DB servers defined in the "Hostname" parameter of the "settings/connection.ini" file in the root of the Repository.
deadline-rcs-1        | 
deadline-rcs-1        | The following errors were encountered:
deadline-rcs-1        | 
deadline-rcs-1        | * deadline-db: Unable to authenticate username 'OU=DEADLINE,O=MEDIAMONKS,CN=deadline-client' using protocol 'MONGODB-X509'. (FranticX.Database.DatabaseConnectionException)
deadline-rcs-1        | An error occurred while trying to create an admin user in the database.
deadline-rcs-1        | An error occurred while trying to migrate the secrets in the database.


mongo --host <your-mongodb-host> --port 27100 --ssl \
  --sslPEMKeyFile /path/to/admin-client.pem \
  --sslCAFile /path/to/ca.crt \
  --authenticationMechanism MONGODB-X509 \
  --authenticationDatabase '$external'


  #!/bin/bash

# Ensure client certificate exists before proceeding
if [ ! -f ~/keys/deadline-client.pfx ]; then
    echo "Error: deadline-client.pfx not found in ~/keys/"
    exit 1
fi

# Ensure the destination directory exists and copy the certificate
mkdir -p /client_certs
cp ~/keys/deadline-client.pfx /client_certs/deadline-client.pfx

# Start MongoDB with the specified config file and log output
/opt/Thinkbox/DeadlineDatabase10/mongo/application/bin/mongod \
  --config /opt/Thinkbox/DeadlineDatabase10/mongo/data/config.conf \
  --logpath /opt/Thinkbox/DeadlineDatabase10/mongo/data/logs/mongod.log &

# Wait for MongoDB to start
until nc -z -v -w30 localhost 27100
do
  echo "Waiting for MongoDB to start..."
  sleep 5
done

echo "MongoDB is up and running."

# Create the MongoDB user using X.509
mongo --host localhost --port 27100 --ssl \
  --sslPEMKeyFile /root/keys/mongodb.pem \
  --sslCAFile /root/keys/ca.crt \
  --authenticationMechanism MONGODB-X509 \
  --authenticationDatabase '$external' <<EOF

use admin
db.getSiblingDB("\$external").runCommand({
   createUser: "OU=DEADLINE,O=MEDIAMONKS,CN=deadline-client",
   roles: [
      { role: "readWrite", db: "deadline10db" },
      { role: "dbAdmin", db: "deadline10db" }
   ]
})

EOF

echo "MongoDB X.509 user created successfully."

# Keep the MongoDB process running in the foreground
wait

