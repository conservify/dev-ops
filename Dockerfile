FROM python:3.4
RUN pip install psycopg2
RUN pip install pytz
COPY app /app
WORKDIR /app
ENTRYPOINT ["python"]
CMD ["query.py"]

