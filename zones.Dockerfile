FROM python:latest

WORKDIR zones

RUN apt-get install -y setuptools

RUN apt-get update



