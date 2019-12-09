import json
import boto3
import uuid
from botocore.exceptions import ClientError


dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('Projects')


def response_error(message, status=500):
    return {
        'statusCode': status,
        'body': {
            'errorMessage': message
        }
    }


def insert(params):
    projectId = str(uuid.uuid4())
    try:
        table.put_item(
            Item={
                'projectId': projectId,
                'name': params['name'],
                'description': params['description'],
                'deadline': params['deadline'],
                'technologies': params['technologies']
            }
        )
        return {
            'statusCode': 200,
            'body': json.dumps({
                'projectId': projectId
            })
        }
    except ClientError as e:
        return response_error(e.response['Error']['Message'])


def update(params):
    try:
        response = table.update_item(
            Key={
                'projectId': params['projectId']
            },
            UpdateExpression='set #name=:name,'
            'description=:description,'
            'deadline=:deadline,'
            'technologies=:technologies',
            ExpressionAttributeValues={
                ':name': params['name'],
                ':description': params['description'],
                ':deadline': params['deadline'],
                ':technologies': params['technologies']
            },
            ExpressionAttributeNames={
                '#name': 'name'
            }
        )
        return {
            'statusCode': 200,
            'body': json.dumps(response)
        }
    except ClientError as e:
        return response_error(e.response['Error']['Message'])


def delete(params):
    try:
        table.delete_item(
            Key={
                'projectId': params['projectId']
            }
        )
        return {
            'statusCode': 204
        }
    except ClientError as e:
        return response_error(e.response['Error']['Message'])


def get(params):
    try:
        response = table.get_item(
            Key={
                'projectId': params['projectId']
            }
        )
        return {
            'statusCode': 200,
            'body': json.dumps(response['Item'])
        }
    except ClientError as e:
        return response_error(e.response['Error']['Message'])


def handler(event, context):
    action = event['action']
    payload = event['payload']

    if action == 'insert':
        return insert(payload)
    elif action == 'update':
        return update(payload)
    elif action == 'delete':
        return delete(payload)
    elif action == 'get':
        return get(payload)
    else:
        return response_error('Not found', 404)
