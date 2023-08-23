#!/bin/bash

# Switch to the ubuntu user
su - ubuntu -c '

sudo apt-get update -y
sudo apt-get install curl -y
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

mkdir -p ~/my-app
cd ~/my-app

npm init -y
npm install express

cat <<EOF > app.js
const express = require("express");
const app = express();
const port = 8000;

app.get("/", (req, res) => {
    res.send("Hello, World! From SSDT_EC2");
});

app.listen(port, () => {
    console.log("Server is running on port ${port}");
});
EOF
node app.js&
'