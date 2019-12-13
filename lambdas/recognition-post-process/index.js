const AWS = require('aws-sdk');
const rekognition = new AWS.Rekognition({
  apiVersion: '2016-06-27',
  region: 'us-east-1'
});
const dynamoDb = new AWS.DynamoDB.DocumentClient();
const uuidv4 = require('uuid/v4');
const S3 = new AWS.S3({ signatureVersion: 'v4' });

exports.handler = async (event, context) => {
  try {
    const snsMessage = JSON.parse(event.Records[0].Sns.Message);
    const jobId = snsMessage.JobId;
    const api = snsMessage.API;
    const status = snsMessage.Status;
    const bucket = snsMessage.Video.S3Bucket;
    const key = snsMessage.Video.S3ObjectName;

    if (status !== 'SUCCEEDED') {
      throw new Error('Recognition failed');
    }

    const s3Object = await S3.headObject({ Bucket: bucket, Key: key }).promise();
    const metadata = s3Object.Metadata;
    console.log('Metadata:', metadata);

    if (api === 'StartContentModeration') {
      const moderationResult = await rekognition.getContentModeration({
        JobId: jobId,
      }).promise();

      console.log('Moderation result:', moderationResult);

      const params = {
        TableName: process.env.DYNAMODB_TABLE,
        Item: {
          id: uuidv4(),
          video: metadata.videourl,
          type: 'Moderation',
          labels: moderationResult.ModerationLabels,
        }
      };
      await dynamoDb.put(params).promise();
    }
    else if (api === 'StartLabelDetection') {
      const labelResult = await rekognition.getLabelDetection({
        JobId: jobId,
      }).promise();

      console.log('Labels result:', labelResult);

      const params = {
        TableName: process.env.DYNAMODB_TABLE,
        Item: {
          id: uuidv4(),
          video: metadata.videourl,
          type: 'Labels',
          labels: labelResult.Labels,
        }
      };
      await dynamoDb.put(params).promise();
    }
    return {
      video: metadata.videoUrl,
      bucket,
      key,
      status: 'Done'
    }
  } catch (error) {
    console.error(error);
    throw error;
  }
};
