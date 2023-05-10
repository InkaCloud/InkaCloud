# Hackathon For Good: La Región de AWS en España al Servicio de la Sociedad
<img width="640" alt="Intro" src="https://github.com/InkaCloud/InkaCloud/assets/132919724/627f2124-486a-4865-bdfb-41588de4b4f5">


## Descripción del Proyecto

### Reto: ONCE

#### Caso de Uso
- Las personas con limitación visual total o parcial tienen dificultades para realizar sus compras en el supermercado. Para solucionar este problema necesitan una herramienta que les permita orientarse y con ello mejorar su experiencia de compra.
- Las dificultades con las que se encuentran basicamente son las de trasladarse por los pasillos del supermercado para ubicar la gondola adecuada, no poder identificar posibles obstáculos inesperados en su ruta como personas u otros carritos de supermercado y luego seleccionar el producto de su preferencia diferenciándolo por marca, tamaño, precio, detalle, etc.
- Otras de las dificultades con las que se encuentra se presentan al momento de realizar el pago al no poder ubicar el código de barras cuando desean pagar en las cajas de autoservicio, verificar los productos que están pagando y verificar el vuelto cuando realizan el pago en efectivo.

#### Propuesta de Solución

**Alcance de la solución:**
- Cubrir la necesidad de movilizarse entre los pasillos del supermercado para ubicar la góndola adecuada.
- No se detectarán obstáculos inesperados como personas u otros carritos de supermercado.
- No se realizará la identificación detallada del producto a comprar una vez se encuentren en la gondola de destino.

**Solución:**
- App de navegación con asistente virtual controlado por voz.
- La interacción con el Usuario se realizará vía comandos y respuestas de voz, para ello el Usario deberá llevar auriculares. Se sugieren auriculares de conducción osea.

<img width="640" alt="App" src="https://github.com/InkaCloud/InkaCloud/assets/132919724/e4b4bad6-d1b3-4c5b-8b8d-abcdfc8139ee">

**Ventajas de la solución**
- Se utiliza el móvil del Usuario sin agregar equipos adicionales.
- La App se puede utilizar en cualquier local de un supermercado siempre y cuando éste se encuentre afiliado.
- La afiliación de un local de un supermercado se realiza con un video del local. Este video debe ser subido a una plataforma Web de afiliación y en esta plataforma el video será analizado con tecnología de Computer Vision con el objetivo de construir un plano 2D del local.
- El plano 2D es transformado y convertido a un formato blanco y negro en donde las zonas blancas son las areas transitables y las zonas negras son las areas no transitables (-góndolas, estanteria, cajas, etc-)

<img width="640" alt="Web" src="https://github.com/InkaCloud/InkaCloud/assets/132919724/b004c7e2-6dad-4a98-81e7-89768692e4fc">


## Diagrama de Arquitectura

![image](https://github.com/InkaCloud/InkaCloud/assets/132919724/3722192f-9ee7-4b16-976d-d03e2db3b43e)

## Descripción Técnica

**Arquitectura de microservicios**

  Applicación Web (Banckend):
  - API para subir archivos de video a S3
  - API para almacenar documentos en DynamoDB (-Datos del supermercado, nombre, dirección del local, etc-)
  - API para transformar plano 2D (-Ejecución de librerias de Computer Vision OpenCV-)

  Apicación Móvil:
  - API invocada por la APP para obtener plano 2D optimizado

**Tecnologías utilizada**

  Applicación Web (Banckend):
  - AWS Amplify: alojamiento de portal web para afiliación de locales de supermercados
  - API Gateway: orquestación de end-points de Apis de backend
  - AWS Lambda: desarrollo de Apis con Python utilizando layer OpenCV (Computer Vision)
  - Amazon S3: datalake para almacenamiento de videos de locales de supermercados y planos 2D
  - Amazon DynamoDB: datamart de datos de locales de supermercado

  Aplicación Móvil:
  - App Android desarrollada en Flutter
  - API Gateway: orquestación de end-points de Apis de frontend
  - AWS Lambda: desarrollo de Apis con Python para alimentar a la App con los planos 2D opimizados del local

## Demo Vídeo

En esta sección podréis subir o enlazar vuestra vídeo presentación. Tenéis dos opciones, **1/** incluir un enlace de YouTube donde tengáis la presentación, **2/** subir un fichero directamente a vuestro repositorio. A continuación, os mostramos los pasos para subir el vídeo:

1.      Una vez creado el repositorio en vuestro fichero README.md, hacéis Click en el icono lápiz.

2.      Y en la parte inferior de la ventana podréis hacer Click y subir ficheros con un tamaño máximo de 10MB.

3.      Una vez se ha subido el vídeo os aparecerá en el fichero README.md. Si excedéis el tamaño permitido (10MB) podéis referencia un enlace de Youtube para que el jurado pueda valorar vuestra presentación.



## Team Members
- Luis Alejandro Ruiz
- Miguel Fuertes

email: miguel.fuertes.oblitas@gmail.com
 
