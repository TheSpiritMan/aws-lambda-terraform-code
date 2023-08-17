import json

def lambda_handler(event, context):
    print("Lambda function was triggered!")
    print(json.dumps(event, indent=2))

    response = {
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/json"
        },
        "body": json.dumps("Lambda function executed successfully")
    }

    return response
