FROM python:3.4
RUN pip install psycopg2
RUN pip install pytz
RUN apt-get update && apt-get install -y gnuplot
COPY app /app
WORKDIR /app
ENTRYPOINT ["python"]
CMD ["query.py"]

