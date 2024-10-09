import os
import json
import boto3
import csv
from datetime import datetime
from collections import defaultdict

s3 = boto3.resource('s3')
ddb = boto3.client('dynamodb', region_name=os.environ['AWS_DEFAULT_REGION'])

def downloadFile(file, bucket, dataSourceName):
    if os.path.exists(f"/tmp/{dataSourceName}"):
        return
    else:
        os.mkdir(f"/tmp/{dataSourceName}")

    s3.meta.client.download_file(bucket, file, f'/tmp/{file}')
    print(file)
    print("OS LISTDIR")
    print(os.listdir(f'/tmp/{dataSourceName}'))

def writeColumnsToDDB(columns, dataSourceName):
    print(columns)
    ddb.put_item(
        TableName=f"{dataSourceName}-columns",
        Item={
            "dashboard": { "S": dataSourceName},
            "columns": {
                "L" : [{"SS": [col, "200"]} for col in columns]
            }
        })

def clear_table(table_name):
    try:
        # Scan the table and delete each item
        response = ddb.scan(TableName=table_name)
        items = response.get('Items', [])
        
        while 'LastEvaluatedKey' in response:
            response = ddb.scan(
                TableName=table_name,
                ExclusiveStartKey=response['LastEvaluatedKey']
            )
            items.extend(response.get('Items', []))
        
        for item in items:
            ddb.delete_item(
                TableName=table_name,
                Key={
                    'serial': item['serial']
                }
            )
        print(f"Cleared table {table_name} successfully.")
    except Exception as e:
        print(f"Error clearing table {table_name}: {e}")

def readFileWriteToDynamoDB(file, dataSourceName):
    # Clear the existing data in the table
    clear_table(f"{dataSourceName}-data")

    compiledDict = {}
    compiledDict['dashboardName'] = dataSourceName
    compiledDict['data'] = {}
    print(f"Opening file: {file}")
    
    with open(file, newline='', encoding='utf-8-sig') as csvfile:
        reader = csv.DictReader(csvfile)
        
        # Check if reader has rows
        rows = list(reader)
        if not rows:
            print("No rows found in CSV file.")
            return
        
        print(f"CSV Headers: {reader.fieldnames}")
        print(f"Total rows (including header): {len(rows)}")
        
        row_count = len(rows) - 1

        for row in rows:
            print(f"Processing row: {row}")

            ddb.put_item(
                TableName=f"{dataSourceName}-data",
                Item={
                    "serial": { "S": str(json.dumps(row['Serial']))},
                    "data": {"S": json.dumps(row)}
                })

            
        # Update metadata
        try:
            today_str = datetime.now().strftime('%m/%d/%Y')
            response = ddb.get_item(
                TableName=f"{dataSourceName}-metadata",
                Key={
                    "dashboard": {"S": dataSourceName}
                }
            )

            if 'Item' in response and 'details' in response['Item']:
                details = response['Item']['details']['L']
                date_exists = False
                
                for detail in details:
                    if detail['M']['date']['S'] == today_str:
                        detail['M']['data']['S'] = str(row_count)
                        date_exists = True
                        break
                
                if not date_exists:
                    details.append({
                        "M": {
                            "date": {"S": today_str},
                            "data": {"S": str(row_count)}
                        }
                    })
                
                ddb.update_item(
                    TableName=f"{dataSourceName}-metadata",
                    Key={
                        "dashboard": {"S": dataSourceName}
                    },
                    UpdateExpression="SET #details = :details",
                    ExpressionAttributeNames={
                        "#details": "details"
                    },
                    ExpressionAttributeValues={
                        ":details": {
                            "L": details
                        }
                    }
                )
            else:
                ddb.update_item(
                    TableName=f"{dataSourceName}-metadata",
                    Key={
                        "dashboard": {"S": dataSourceName}
                    },
                    UpdateExpression="SET #details = :details",
                    ExpressionAttributeNames={
                        "#details": "details"
                    },
                    ExpressionAttributeValues={
                        ":details": {
                            "L": [
                                {
                                    "M": {
                                        "date": {"S": today_str},
                                        "data": {"S": str(row_count)}
                                    }
                                }
                            ]
                        }
                    }
                )
            writeColumnsToDDB(reader.fieldnames, dataSourceName)
            return {
                'statusCode': 200,
                'body': 'Item updated successfully'
            }
        except Exception as e:
            print(e)
            return {
                'statusCode': 500,
                'body': 'Error updating item'
            }

def lambda_handler(event, context):
    print(event)
    for record in event['Records']:
        file = record['s3']['object']['key']
        bucket = record['s3']['bucket']['name']
        dataSourceName = file.split('/')[0]
        print(file, bucket, dataSourceName)
        downloadFile(file, bucket, dataSourceName)
        readFileWriteToDynamoDB(f"/tmp/{file}", dataSourceName)
