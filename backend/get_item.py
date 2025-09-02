import json
import boto3
import logging

#Configure logging
# test comment

logger = logging.getLogger()
logger.setLevel(logging.INFO)

dynamodb = boto3.resource('dynamodb', region_name='ca-central-1')

table = dynamodb.Table('iac-counter')

def lambda_handler(event, context):
    logger.info('Event: %s', event)
    
    response = table.get_item(
        Key={
            'countID': 0
            }
    )
    item = response['Item']['counter']
    
    return {
        'statusCode': 200,
        'body': item
    }