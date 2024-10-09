import os
import json
import boto3

ddb = boto3.client('dynamodb', region_name=os.environ['AWS_DEFAULT_REGION'])

def getDataFromDynamodb(dataSourceName):
    ddbTable = f"{dataSourceName}-data"
    last_evaluated_key = None
    results = {
        'Items': []
    }

    while True:
        if last_evaluated_key:
            response = ddb.scan(
                TableName=ddbTable,
                ExclusiveStartKey=last_evaluated_key
            )
        else:
            response = ddb.scan(TableName=ddbTable)
        
        last_evaluated_key = response.get('LastEvaluatedKey')
        
        results['Items'].extend(response['Items'])

        if not last_evaluated_key:
            break

    return results

def lambda_handler(event, context):
    print(event)

    body = json.loads(event['body'])
    dataSourceName = body['data']

    data = getDataFromDynamodb(dataSourceName)
    
    # Convert the data to a list of dictionaries suitable for MUI DataGrid
    rows = [
        {**item, 'id': item['serial']['S']} for item in data['Items']
    ]
    print(len(rows))

    response = {
        'statusCode': 200,
        'headers': {
            "title": "getData",
            "Access-Control-Allow-Headers": "Content-Type",
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "OPTIONS,POST"
        },
        'body': json.dumps(rows),
    }
    
    return response
