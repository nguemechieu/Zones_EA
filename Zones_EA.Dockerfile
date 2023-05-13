

ARG APP_IMAGE=python:latest

FROM $APP_IMAGE AS base

FROM base as builder

RUN  pip install --upgrade pip

WORKDIR /install

COPY requirements.txt /requirements.txt

RUN pip install --install-option="--prefix=/install" -r /requirements.txt

FROM base
ENV FLASK_APP routes.py
WORKDIR /Zones_EA
COPY --from=builder /install /usr/local
ADD . /zones_ea.py

ENTRYPOINT ["python", "-m", "flask", "run", "--host=0.0.0.0"]