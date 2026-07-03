import json
import os
import boto3
from botocore.exceptions import ClientError

BUCKET_NAME = os.environ.get('BUCKET_NAME', 'magic-show-data')
OBJECT_KEY = 'data.json'
PAGE_TITLE = os.environ.get('PAGE_TITLE', 'MPFH — Ответы зрителей')
AWS_KEY = os.environ.get('AWS_ACCESS_KEY_ID', '')
AWS_SECRET = os.environ.get('AWS_SECRET_ACCESS_KEY', '')

s3 = boto3.client(
    's3',
    endpoint_url='https://storage.yandexcloud.net',
    region_name='ru-central1',
    aws_access_key_id=AWS_KEY,
    aws_secret_access_key=AWS_SECRET,
)

def save_data(data):
    try:
        body = json.dumps(data, ensure_ascii=False, indent=2)
        s3.put_object(
            Bucket=BUCKET_NAME,
            Key=OBJECT_KEY,
            Body=body.encode('utf-8'),
            ContentType='application/json; charset=utf-8',
            StorageClass='STANDARD',
        )
        return True
    except ClientError as e:
        print(f'S3 put error: {e}')
        raise


def load_data():
    try:
        response = s3.get_object(Bucket=BUCKET_NAME, Key=OBJECT_KEY)
        body = response['Body'].read().decode('utf-8')
        return json.loads(body)
    except ClientError as e:
        if e.response['Error']['Code'] == 'NoSuchKey':
            return None
        print(f'S3 get error: {e}')
        raise


def generate_html(data):
    instruction = data.get('instruction', '')
    replies = data.get('replies', [])

    items_html = '\n'.join(
        f'            <li class="reply-item">\n'
        f'              <span class="reply-number">{i + 1}</span>\n'
        f'              <span class="reply-text">{reply}</span>\n'
        f'            </li>'
        for i, reply in enumerate(replies)
    )

    return f'''<!DOCTYPE html>
<html lang="ru">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>{PAGE_TITLE}</title>
  <style>
    * {{
      margin: 0;
      padding: 0;
      box-sizing: border-box;
    }}

    body {{
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
      min-height: 100vh;
      background: linear-gradient(135deg, #0f0c29 0%, #302b63 50%, #24243e 100%);
      color: #ffffff;
      display: flex;
      align-items: center;
      justify-content: center;
      padding: 20px;
    }}

    .container {{
      max-width: 680px;
      width: 100%;
      background: rgba(255, 255, 255, 0.05);
      border: 1px solid rgba(255, 255, 255, 0.1);
      border-radius: 24px;
      padding: 40px;
      backdrop-filter: blur(10px);
    }}

    h1 {{
      font-size: 1.5rem;
      font-weight: 700;
      text-align: center;
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
      background-clip: text;
      margin-bottom: 8px;
    }}

    .instruction {{
      text-align: center;
      color: rgba(255, 255, 255, 0.6);
      font-size: 1rem;
      margin-bottom: 32px;
      padding-bottom: 24px;
      border-bottom: 1px solid rgba(255, 255, 255, 0.08);
    }}

    .replies-list {{
      list-style: none;
      display: flex;
      flex-direction: column;
      gap: 12px;
    }}

    .reply-item {{
      display: flex;
      align-items: flex-start;
      gap: 16px;
      padding: 16px 20px;
      background: rgba(255, 255, 255, 0.06);
      border: 1px solid rgba(255, 255, 255, 0.08);
      border-radius: 14px;
      transition: all 0.2s;
    }}

    .reply-item:hover {{
      background: rgba(255, 255, 255, 0.1);
      transform: translateX(4px);
    }}

    .reply-number {{
      display: flex;
      align-items: center;
      justify-content: center;
      min-width: 32px;
      height: 32px;
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      border-radius: 50%;
      font-size: 0.85rem;
      font-weight: 700;
      flex-shrink: 0;
    }}

    .reply-text {{
      font-size: 1.05rem;
      line-height: 1.6;
      color: rgba(255, 255, 255, 0.9);
      padding-top: 4px;
    }}

    .empty-state {{
      text-align: center;
      padding: 40px 20px;
      color: rgba(255, 255, 255, 0.4);
      font-size: 1rem;
    }}

    @media (max-width: 480px) {{
      .container {{
        padding: 24px 16px;
      }}

      h1 {{
        font-size: 1.2rem;
      }}

      .reply-item {{
        padding: 12px 14px;
        gap: 12px;
      }}

      .reply-text {{
        font-size: 0.95rem;
      }}
    }}
  </style>
</head>
<body>
  <div class="container">
    <h1>Ответы зрителей</h1>
    <div class="instruction">{instruction}</div>
    <ul class="replies-list">
      {items_html if replies else '<li class="empty-state">Ответов пока нет</li>'}
    </ul>
  </div>
</body>
</html>'''


def handler(event, context):
    try:
        if isinstance(event, str):
            event = json.loads(event) if event.strip() else {}

        http_method = event.get('httpMethod', 'GET')

        if http_method == 'POST':
            if event.get('isBase64Encoded', False):
                import base64
                body = base64.b64decode(event['body']).decode('utf-8')
            else:
                body = event.get('body', '{}')

            data = json.loads(body) if isinstance(body, str) else body

            if not isinstance(data, dict) or 'replies' not in data:
                return {
                    'statusCode': 400,
                    'headers': {
                        'Content-Type': 'application/json',
                        'Access-Control-Allow-Origin': '*',
                    },
                    'body': json.dumps({'error': 'Invalid data: "replies" field is required'}, ensure_ascii=False),
                }

            save_data(data)

            return {
                'statusCode': 200,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*',
                    'Access-Control-Allow-Methods': 'POST, GET, OPTIONS',
                    'Access-Control-Allow-Headers': 'Content-Type',
                },
                'body': json.dumps({'status': 'ok'}, ensure_ascii=False),
            }

        elif http_method == 'GET':
            data = load_data()

            if data is None:
                html = generate_html({'instruction': 'Ожидание данных...', 'replies': []})
            else:
                html = generate_html(data)

            return {
                'statusCode': 200,
                'headers': {
                    'Content-Type': 'text/html; charset=utf-8',
                },
                'body': html,
            }

        elif http_method == 'OPTIONS':
            return {
                'statusCode': 200,
                'headers': {
                    'Access-Control-Allow-Origin': '*',
                    'Access-Control-Allow-Methods': 'POST, GET, OPTIONS',
                    'Access-Control-Allow-Headers': 'Content-Type',
                },
                'body': '',
            }

        else:
            return {
                'statusCode': 405,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*',
                },
                'body': json.dumps({'error': f'Method {http_method} not allowed'}, ensure_ascii=False),
            }

    except Exception as e:
        print(f'Handler error: {e}')
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
            },
            'body': json.dumps({'error': str(e)}, ensure_ascii=False),
        }
