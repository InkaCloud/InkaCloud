import boto3
import zipfile
import os
cloudformation = boto3.client('cloudformation')

# Crear un archivo zip para la función Lambda
with zipfile.ZipFile('function.zip', 'w') as zipf:
    zipf.write('../../backend/index.py')

# Subir el archivo zip a S3
s3 = boto3.client('s3')

s3.upload_file('function.zip', 'dev-python-backend-inkacloud', 'function.zip')

with open("../templates/cloudformation-lambda.yaml", 'r') as file:
    template_body=file.read()

response = cloudformation.create_stack(
    StackName='LambdaStack',
    TemplateBody=template_body,
    Capabilities=[
        'CAPABILITY_IAM',
    ]
)

print(response)
