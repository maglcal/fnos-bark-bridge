FROM python:3.12-alpine
WORKDIR /app
COPY app.py .
ENV PORT=8081
EXPOSE 8081
CMD ["python", "app.py"]
