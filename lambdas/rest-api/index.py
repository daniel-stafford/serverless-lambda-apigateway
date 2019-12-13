import json
import boto3
import uuid
from botocore.exceptions import ClientError


dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('Projects')


def response_error(message, status=500):
    error_type = 'InternalError'

    if status == 404:
        error_type = 'NotFound'

    raise Exception(json.dumps({
        'error': error_type,
        'message': message
    }))


def insert(params):
    project_id = str(uuid.uuid4())
    item = {
        'projectId': project_id,
        'name': params['name'],
        'description': params['description'],
        'deadline': params['deadline'],
        'technologies': params['technologies']
    }
    try:
        table.put_item(
            Item=item
        )
        return item
    except ClientError as e:
        return response_error(e.response['Error']['Message'])


def update(project_id, params):
    try:
        table.update_item(
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
        item = {
            'projectId': project_id,
            'name': params['name'],
            'description': params['description'],
            'deadline': params['deadline'],
            'technologies': params['technologies']
        }
        return item
    except KeyError:
        return response_error('Not found', status=404)
    except ClientError as e:
        return response_error(e.response['Error']['Message'])


def delete(project_id):
    try:
        table.delete_item(
            Key={
                'projectId': project_id
            }
        )
    except KeyError:
        return response_error('Not found', status=404)
    except ClientError as e:
        return response_error(e.response['Error']['Message'])


def get(project_id):
    try:
        response = table.get_item(
            Key={
                'projectId': project_id
            }
        )
        return response['Item']
    except KeyError:
        return response_error('Not found', status=404)
    except ClientError as e:
        return response_error(e.response['Error']['Message'])


def get_all():
    try:
        response = table.scan()
        data = response['Items']

        while 'LastEvaluatedKey' in response:
            response = table.scan()
            data.extend(response['Items'])
        return data
    except ClientError:
        return response_error('Internal error')


def handler(event, context):
    action = event['action']
    payload = event.get('payload')

    if action == 'get_all':
        return get_all()
    elif action == 'insert':
        return insert(payload)
    elif action == 'update':
        return update(event['projectId'], payload)
    elif action == 'delete':
        return delete(event['projectId'])
    elif action == 'get':
        return get(event['projectId'])
    else:
        return response_error('Not found', 404)
