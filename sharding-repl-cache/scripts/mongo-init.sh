#!/bin/bash

###
# Инициализируем бд
###

docker compose exec -T sharding-repl-cache mongosh <<EOF
use somedb
for(var i = 0; i < 1000; i++) db.helloDoc.insertOne({age:i, name:"ly"+i})
db.helloDoc.countDocuments() 
EOF