import boto3

cloudformation = boto3.client('cloudformation')

with open("../templates/cloudformation-s3.yaml", 'r') as file:
    template_body=file.read()

response = cloudformation.create_stack(
    StackName='MyStackS3',
    TemplateBody=template_body
)

print(response)
