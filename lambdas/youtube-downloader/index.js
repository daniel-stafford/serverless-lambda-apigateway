const stream = require('stream');
const youtubeDownloader = require('youtube-dl');
const AWS = require('aws-sdk');
const S3 = new AWS.S3({ signatureVersion: 'v4' });
const rekognition = new AWS.Rekognition({apiVersion: '2016-06-27', region: 'us-east-1'});

async function startRekognitionJobs(bucket, key) {
  key = "e881c2ac-84e6-4c3d-ae6e-6ca14e68cb17.mp4";
  const fileName = key.substring(key.lastIndexOf('/') + 1);
  console.log(`Recognition: ${fileName}, ${bucket}, ${key}`);

  try {
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
      }
    };
    const moderationJob = await rekognition.startContentModeration(params).promise();
    const labelJob = await rekognition.startLabelDetection(params).promise();
    console.log('Moderation job:', moderationJob);
    console.log('Label job:', labelJob);
  } catch (error) {
    console.error(`Failed to start recognition jobs: ${bucket}/${key}`, error);
  }
}

exports.handler = async (event, context, callback) => {   
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
    },
  });

  upload.on('httpUploadProgress', (progress) => {
    console.log(`[${event.videoUrl}] downloading ...`, progress);
  });

  try {
    await upload.send();
    await startRekognitionJobs(bucket, key);
    callback(null, {
      bucketName: bucket,
      key,
      url: `s3://${bucket}/${key}`
    });
  } catch (error) {
    callback(error);
  }

  downloader.pipe(downloadStream);
}
