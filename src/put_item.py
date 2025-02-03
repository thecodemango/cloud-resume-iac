import json
import boto3
import logging

#Configure logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

dynamodb = boto3.resource('dynamodb', region_name='ca-central-1')

table = dynamodb.Table('iac-counter')

def lambda_handler(event, context):
    logger.info('Event: %s', event)

    n = event['pathParameters']['n']

    if int(n) < 0:
        raise ValueError("The value of the counter must be a positive int. Check pathParameters value")

    table.update_item(
        Key={
            'countID': 0
            },
            #Workaround. counter is a reserved word in DynamoDB
            ExpressionAttributeNames={"#c":"counter"},
            UpdateExpression='SET #c = :val1',
            ExpressionAttributeValues={
                ':val1': n
            }
    )
    
    return {
        'statusCode': 200
    }