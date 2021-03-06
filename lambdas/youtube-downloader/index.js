const stream = require('stream');
const youtubeDownloader = require('youtube-dl');
const AWS = require('aws-sdk');
const S3 = new AWS.S3({ signatureVersion: 'v4' });
const rekognition = new AWS.Rekognition({
  apiVersion: '2016-06-27',
  region: 'us-east-1'
});

function startRekognitionJobs(bucket, key, minConfidence) {
  const fileName = key.substring(key.lastIndexOf('/') + 1);
  console.log(`Recognition: ${fileName}, ${bucket}, ${key}`);

  const params = {
    Video: {
      S3Object: {
        Bucket: bucket,
        Name: key,
      },
    },
    NotificationChannel: {
      SNSTopicArn: process.env.SNS_ARN,
      RoleArn: process.env.ROLE_ARN,
    },
    MinConfidence: minConfidence,
  };
  rekognition.startContentModeration(params).promise();
  rekognition.startLabelDetection(params).promise();
}

exports.handler = (event, context, callback) => {
  if (!event.videoUrl) {
    return callback(new Error('videoUrl missing in event'));
  }
  const downloadStream = new stream.PassThrough();
  const downloader = youtubeDownloader(
    event.videoUrl,
    ['--format=best[ext=mp4]'],
    {
      maxBuffer: Infinity
    }
  ).once('error', callback);

  const key = `${context.awsRequestId}.mp4`;
  const bucket = process.env.BUCKET_NAME;

  const upload = new AWS.S3.ManagedUpload({
    params: {
      Bucket: bucket,
      Key: key,
      Body: downloadStream,
      Metadata: {
        videoUrl: event.videoUrl,
      }
    },
  });

  upload.on('httpUploadProgress', (progress) => {
    console.log(`[${event.videoUrl}] downloading ...`, progress);
  });

  const minConfidence = event.minConfidence || 90;

  upload.send((error) => {
    if (error) {
      callback(error);
    } else {
      startRekognitionJobs(bucket, key, minConfidence);
      callback(null, {
        bucketName: bucket,
        key,
        url: `s3://${bucket}/${key}`
      });
    }
  });

  downloader.pipe(downloadStream);
}
