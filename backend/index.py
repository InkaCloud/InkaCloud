import boto3
import cv2
import numpy as np
import json

s3 = boto3.client('s3')

def lambda_handler(event, context):
    # Recupera el nombre del bucket y el key del archivo que se ha subido a S3
    bucket = event['Records'][0]['s3']['bucket']['name']
    key = event['Records'][0]['s3']['object']['key']

    # Descarga la imagen del bucket de S3
    download_path = '/tmp/{}'.format(key)
    s3.download_file(bucket, key, download_path)

    # Carga la imagen en escala de grises con OpenCV
    imagen = cv2.imread(download_path, 0)

    # Crea un arreglo bidimensional de la imagen donde 0 es blanco y 1 es negro
    imagen_binaria = [[1 if pixel < 128 else 0 for pixel in fila] for fila in imagen]

    # Convierte el arreglo a formato JSON
    imagen_json = json.dumps(imagen_binaria)

    # Sube el archivo JSON a otro bucket de S3
    upload_path = '/tmp/processed-{}'.format(key)
    with open(upload_path, 'w') as file:
        file.write(imagen_json)
    s3.upload_file(upload_path, 'processed-files-inkacloud', 'processed-{}'.format(key))
