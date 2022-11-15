FROM python:latest

RUN apt update

WORKDIR /app

ADD ./url_app.tar.gz .

RUN pip install --upgrade pip

RUN pip install -r requirements.txt

EXPOSE 5000

ENTRYPOINT FLASK_APP=application flask run --host=0.0.0.0