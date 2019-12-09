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
    project_id = str(uuid.uuid4())
    try:
        table.put_item(
            Item={
                'projectId': project_id,
                'name': params['name'],
                'description': params['description'],
                'deadline': params['deadline'],
                'technologies': params['technologies']
            }
        )
        return {
            'statusCode': 200,
            'body': json.dumps({
                'projectId': project_id
            })
        }
    except ClientError as e:
        return response_error(e.response['Error']['Message'])


def update(project_id, params):
    try:
        response = table.update_item(
            Key={
                'projectId': project_id
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


def delete(project_id):
    try:
        table.delete_item(
            Key={
                'projectId': project_id
            }
        )
        return {
            'statusCode': 204
        }
    except ClientError as e:
        return response_error(e.response['Error']['Message'])


def get(project_id):
    try:
        response = table.get_item(
            Key={
                'projectId': project_id
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
        return update(event['projectId'], payload)
    elif action == 'delete':
        return delete(event['projectId'])
    elif action == 'get':
        return get(event['projectId'])
    else:
        return response_error('Not found', 404)
