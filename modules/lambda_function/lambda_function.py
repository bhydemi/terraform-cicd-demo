import json
import os
import urllib.parse

def lambda_handler(event, context):
    """
    Lambda function triggered by S3 events.
    Processes uploaded files and logs information.
    """

    environment = os.environ.get('ENVIRONMENT', 'unknown')

    print(f"Processing S3 event in {environment} environment")

    # Process each S3 event record
    for record in event.get('Records', []):
        # Get bucket and object information
        bucket = record['s3']['bucket']['name']
        key = urllib.parse.unquote_plus(record['s3']['object']['key'])
        size = record['s3']['object']['size']
        event_name = record['eventName']

        print(f"Event: {event_name}")
        print(f"Bucket: {bucket}")
        print(f"Key: {key}")
        print(f"Size: {size} bytes")

        # Here you could add custom processing logic
        # For example: image processing, data validation, etc.

    return {
        'statusCode': 200,
        'body': json.dumps({
            'message': f'Successfully processed {len(event.get("Records", []))} S3 events',
            'environment': environment
        })
    }
