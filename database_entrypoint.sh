#!/bin/bash

cp ~/keys/deadline-client.pfx /client_certs/deadline-client.pfx

/opt/Thinkbox/DeadlineDatabase10/mongo/application/bin/mongod --config /opt/Thinkbox/DeadlineDatabase10/mongo/data/config.conf

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
