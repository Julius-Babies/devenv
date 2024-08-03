FROM ubuntu:latest
LABEL authors="Julius Babies"

WORKDIR /app

RUN apt-get update
RUN apt-get install nginx -y
RUN apt-get install openssl -y

COPY ./start.sh /app/start.sh
COPY ./nginx/ssl.conf /ssl.conf
COPY ./template.conf /app/template.conf

EXPOSE 80 443

CMD ["bash", "start.sh"]