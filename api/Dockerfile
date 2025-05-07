FROM python:3.12-alpine

WORKDIR /code/api

RUN python3 -m pip install --upgrade pip

COPY ./requirements.txt /code/api/requirements.txt
RUN pip install --no-cache-dir -r /code/api/requirements.txt

COPY ./src /code/api

EXPOSE 8000

CMD ["fastapi", "run", "main.py", "--port", "8000"]
