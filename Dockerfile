FROM python:3.12.10-alpine3.20

RUN apk update && apt install --no-cache cmake && pip install --no-cache-dir flask

WORKDIR /app

COPY docker/app.py .

EXPOSE 10000

ENTRYPOINT [ "python", "app.py"]
CMD ["--host", "0.0.0.0", "--port", "10000"]