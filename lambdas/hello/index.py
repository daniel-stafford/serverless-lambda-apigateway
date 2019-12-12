def handler(event, context):
    name = event['name']
    return 'Hello {}! Welcome to AWS Lambda'.format(name)
