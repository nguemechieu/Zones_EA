FROM python:latest

WORKDIR Zones_EA

COPY ../



CMD [ "python", "zones_ea.py" ]
