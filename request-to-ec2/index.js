const http = require("http");

exports.handler = async (event) => {
  const ec2PrivateIP = process.env.EC2_PRIVATE_IP;

  const options = {
    hostname: ec2PrivateIP,
    port: 8000,
    path: "/",
    method: "GET",
  };

  const response = await new Promise((resolve, reject) => {
    const req = http.request(options, (res) => {
      let data = "";
      res.on("data", (chunk) => {
        data += chunk;
      });
      res.on("end", () => {
        resolve({
          statusCode: res.statusCode,
          body: data,
        });
      });
    });

    req.on("error", (error) => {
      reject(error);
    });

    req.end();
  });

  return response;
};
