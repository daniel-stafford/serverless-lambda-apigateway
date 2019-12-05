const AWS = require('aws-sdk');
const rekognition = new AWS.Rekognition({apiVersion: '2016-06-27', region: 'us-east-1'});

exports.handler = async (event, context, callback) => {
  try {
    const snsMessage = JSON.parse(event.Records[0].Sns.Message);
    console.log('SNS message:', snsMessage);

    const jobId = snsMessage.JobId;
    const api = snsMessage.API;
    const status = snsMessage.Status;
    const bucket = snsMessage.Video.S3Bucket;
    const key = snsMessage.Video.S3ObjectName;

    if (status !== 'SUCCEEDED') {
      throw new Error('Recognition failed');
    }

    const params = {
      JobId: jobId,
    };

    if (api === 'StartContentModeration') {
      const moderationResult = await rekognition.getContentModeration(params).promise();
      console.log('Moderation:', moderationResult.ModerationLabels);
    }
    else if (api === 'StartLabelDetection') {
      const result = await rekognition.getLabelDetection(params).promise();
      console.log('Labels:', result.Labels);
    }
    callback(null, { message: 'Done!' });
  } catch (error) {
    console.error(error);
    callback(error);
  }
};
