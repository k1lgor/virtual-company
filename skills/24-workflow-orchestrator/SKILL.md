---
name: workflow-orchestrator
description: Use this for designing complex workflows, scheduled jobs, and task orchestration (Airflow, Prefect, Temporal, Cron, Celery).
---

# Workflow Orchestrator

You design and implement reliable, scheduled, and event-driven workflows.

## When to use

- "Schedule this script to run every night."
- "Create a pipeline for data processing."
- "Chain these tasks together."

## Instructions

1. DAG Design:
   - Structure tasks as a Directed Acyclic Graph (DAG).
   - Clearly define dependencies between tasks.
2. Tooling:
   - Use Airflow/Prefect for complex, data-heavy pipelines.
   - Use Celery/Bull queues for async background tasks in web apps.
   - Use Cron for simple system-level schedules.
3. Reliability:
   - Implement retries with exponential backoff.
   - Set alerts for failed tasks.
   - Ensure idempotency (running the workflow twice doesn't break things).

## Examples

### 1. Airflow DAG for Data Pipeline

```python
from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.operators.bash import BashOperator
from datetime import datetime, timedelta
import pandas as pd

default_args = {
    'owner': 'data-team',
    'depends_on_past': False,
    'start_date': datetime(2024, 1, 1),
    'email': ['alerts@company.com'],
    'email_on_failure': True,
    'email_on_retry': False,
    'retries': 3,
    'retry_delay': timedelta(minutes=5),
    'retry_exponential_backoff': True,
}

dag = DAG(
    'daily_sales_pipeline',
    default_args=default_args,
    description='Process daily sales data',
    schedule_interval='0 2 * * *',  # Run at 2 AM daily
    catchup=False,
    tags=['sales', 'etl'],
)

def extract_data(**context):
    """Extract data from source"""
    # Idempotent: check if already processed
    execution_date = context['ds']
    print(f"Extracting data for {execution_date}")
    # Your extraction logic here
    return f"data_{execution_date}.csv"

def transform_data(**context):
    """Transform the extracted data"""
    ti = context['ti']
    filename = ti.xcom_pull(task_ids='extract')

    df = pd.read_csv(filename)
    # Transformation logic
    df['total'] = df['quantity'] * df['price']

    output_file = f"transformed_{context['ds']}.csv"
    df.to_csv(output_file, index=False)
    return output_file

def load_data(**context):
    """Load data to warehouse"""
    ti = context['ti']
    filename = ti.xcom_pull(task_ids='transform')
    print(f"Loading {filename} to warehouse")
    # Load logic here

# Define tasks
extract = PythonOperator(
    task_id='extract',
    python_callable=extract_data,
    dag=dag,
)

transform = PythonOperator(
    task_id='transform',
    python_callable=transform_data,
    dag=dag,
)

load = PythonOperator(
    task_id='load',
    python_callable=load_data,
    dag=dag,
)

cleanup = BashOperator(
    task_id='cleanup',
    bash_command='rm -f /tmp/data_{{ ds }}*.csv',
    dag=dag,
)

# Set dependencies
extract >> transform >> load >> cleanup
```

### 2. Celery Task Queue for Background Jobs

```python
# tasks.py
from celery import Celery
from celery.utils.log import get_task_logger
import time

app = Celery('tasks', broker='redis://localhost:6379/0')
logger = get_task_logger(__name__)

# Configure retries
app.conf.task_acks_late = True
app.conf.task_reject_on_worker_lost = True

@app.task(bind=True, max_retries=3)
def send_email(self, user_id, email_type):
    """Send email with retry logic"""
    try:
        logger.info(f"Sending {email_type} email to user {user_id}")
        # Email sending logic
        # Simulate potential failure
        if email_type == 'verification':
            # Your email logic here
            pass
        return f"Email sent to user {user_id}"
    except Exception as exc:
        # Retry with exponential backoff
        logger.error(f"Failed to send email: {exc}")
        raise self.retry(exc=exc, countdown=2 ** self.request.retries)

@app.task
def process_image(image_path):
    """Process uploaded image"""
    logger.info(f"Processing image: {image_path}")
    # Image processing logic
    time.sleep(2)  # Simulate processing
    return f"Processed: {image_path}"

@app.task
def generate_report(report_id):
    """Generate monthly report"""
    logger.info(f"Generating report {report_id}")
    # Report generation logic
    return {"report_id": report_id, "status": "completed"}

# Usage in your application:
# from tasks import send_email
# send_email.delay(user_id=123, email_type='welcome')
```

### 3. Cron Job with Retry Logic (Python Script)

```python
#!/usr/bin/env python3
"""
Scheduled backup script with retry logic
Add to crontab: 0 3 * * * /usr/bin/python3 /path/to/backup.py
"""

import subprocess
import time
import logging
from datetime import datetime
import smtplib
from email.message import EmailMessage

logging.basicConfig(
    filename='/var/log/backup.log',
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)

def send_alert(subject, message):
    """Send email alert on failure"""
    msg = EmailMessage()
    msg.set_content(message)
    msg['Subject'] = subject
    msg['From'] = 'backup@company.com'
    msg['To'] = 'admin@company.com'

    try:
        with smtplib.SMTP('localhost') as s:
            s.send_message(msg)
    except Exception as e:
        logging.error(f"Failed to send alert: {e}")

def backup_database(max_retries=3):
    """Backup database with retry logic"""
    backup_file = f"/backups/db_backup_{datetime.now().strftime('%Y%m%d_%H%M%S')}.sql"

    for attempt in range(1, max_retries + 1):
        try:
            logging.info(f"Starting backup attempt {attempt}/{max_retries}")

            # Run backup command
            result = subprocess.run(
                ['pg_dump', '-U', 'postgres', '-d', 'mydb', '-f', backup_file],
                capture_output=True,
                text=True,
                timeout=300
            )

            if result.returncode == 0:
                logging.info(f"Backup successful: {backup_file}")

                # Verify backup file exists and has content
                import os
                if os.path.exists(backup_file) and os.path.getsize(backup_file) > 0:
                    return True
                else:
                    raise Exception("Backup file is empty or missing")
            else:
                raise Exception(f"Backup command failed: {result.stderr}")

        except Exception as e:
            logging.error(f"Backup attempt {attempt} failed: {e}")

            if attempt < max_retries:
                # Exponential backoff
                wait_time = 2 ** attempt
                logging.info(f"Retrying in {wait_time} seconds...")
                time.sleep(wait_time)
            else:
                # Final failure
                error_msg = f"Backup failed after {max_retries} attempts"
                logging.critical(error_msg)
                send_alert("CRITICAL: Database Backup Failed", error_msg)
                return False

    return False

if __name__ == '__main__':
    logging.info("=== Backup job started ===")
    success = backup_database()

    if success:
        logging.info("=== Backup job completed successfully ===")
        exit(0)
    else:
        logging.error("=== Backup job failed ===")
        exit(1)
```
