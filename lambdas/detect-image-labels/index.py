import boto3
import os
from io import BytesIO
import contextlib
from botocore.vendored import requests
import uuid


s3 = boto3.client('s3')
rekognition = boto3.client('rekognition', 'us-east-1')


def download_image(url):
    bucket = os.environ['BUCKET']
    key = str(uuid.uuid4())

    with contextlib.closing(requests.get(url, stream=True, verify=False)) \
            as response:
        fp = BytesIO(response.content)
        s3.upload_fileobj(fp, bucket, key)

    return (bucket, key)


def recognize_labels(bucket, key, max_labels, min_confidence):
    response = rekognition.detect_labels(
        Image={
            "S3Object": {
                "Bucket": bucket,
                "Name": key,
            }
        },
        MaxLabels=max_labels,
        MinConfidence=min_confidence
    )
    return response['Labels']


def handler(event, context):
    if 'imageUrl' not in event:
        raise Exception('No imageUrl provided')
    image_url = event['imageUrl']
    max_labels = event.get('maxLabels', 10)
    min_confidence = event.get('minConfidence', 90)
    bucket, key = download_image(image_url)
    labels = recognize_labels(bucket, key, max_labels, min_confidence)
    return labels
