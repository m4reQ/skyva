FROM python:3.12-alpine

WORKDIR /code/mqtt

RUN python3 -m pip install --upgrade pip

COPY ./requirements.txt /code/mqtt/requirements.txt
RUN pip install --no-cache-dir -r /code/mqtt/requirements.txt

COPY ./src /code/mqtt

CMD ["python", "main.py"]
