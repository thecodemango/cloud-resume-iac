import json
import boto3
import logging

#Configure logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

dynamodb = boto3.resource('dynamodb', region_name='ca-central-1')
#Change the table name so its not hardcoded
table = dynamodb.Table('iac-counter')

def lambda_handler(event, context):
    logger.info('Event: %s', event)
    
    n = event['pathParameters']['n']
    
    table.update_item(
        Key={
            'countID': 0
            },
            # To workaorund the fact that counter is a reserved word in DynamoDB
            ExpressionAttributeNames={"#c":"counter"},
            UpdateExpression='SET #c = :val1',
            ExpressionAttributeValues={
                ':val1': n
            }
    )
    
    return {
        'statusCode': 200,
        'body': json.dumps(event)
    }