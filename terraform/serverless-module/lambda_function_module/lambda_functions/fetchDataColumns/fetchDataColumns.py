import os
import json
import boto3
import csv
from collections import defaultdict

ddb = boto3.client('dynamodb', region_name=os.environ['AWS_DEFAULT_REGION'])

def getDataFromDynamodb(dataSourceName):
    ddbTable = f"{dataSourceName}-columns"
    dashboardData = ddb.query(
        ExpressionAttributeValues={
            ':v1': {
                'S': dataSourceName,
            }
        },
        KeyConditionExpression='dashboard = :v1',
        TableName=ddbTable,
    )

    
    print(dashboardData)
    
    return dashboardData

def lambda_handler(event, context):
    print(event)
    body = json.loads(event['body'])
    dataSourceName = body['data']

    response = {
        'statusCode': 200,
        'headers': {
            "title": "getDataColumns",
            "Access-Control-Allow-Headers" : "Content-Type",
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "OPTIONS,POST"
        },
        'body': json.dumps(getDataFromDynamodb(dataSourceName)),
    };
    
    return response