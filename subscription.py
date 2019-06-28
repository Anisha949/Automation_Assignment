import boto3
import os

# Create an SNS client
sns = boto3.client('sns')

# Publish a simple message to the specified SNS topic
response = sns.publish(
    TopicArn=os.environ("TopicArn"),    
    Message='Hello World!',    
)

# Print out the response
print(response)
