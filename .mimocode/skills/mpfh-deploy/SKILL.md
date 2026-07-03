---
name: mpfh-deploy
description: Use when deploying MPFH to Yandex Cloud (Cloud Functions, S3, API Gateway)
---

# MPFH Deploy

## Prerequisites

- Yandex Cloud CLI (`yc`) installed and authenticated
- Bucket `magic-show-data` created in `ru-central1`
- Service account with `editor` role for Cloud Functions and S3

## Deployment Steps

### 1. Build Frontend

```bash
npm run build
```

Output: `dist/` directory.

### 2. Deploy Backend (Cloud Function)

```bash
# Package handler
cd backend
zip -r function.zip handler.py requirements.txt

# Deploy function
yc serverless function create \
  --name mpfh-handler \
  --runtime python312 \
  --entrypoint handler.handler \
  --memory 128m \
  --execution-timeout 30s \
  --environment BUCKET_NAME=magic-show-data \
  --environment PAGE_TITLE="MPFH — Ответы зрителей" \
  --source-path function.zip
```

### 3. Setup API Gateway

Create `openapi.yaml` with your function ID:

```yaml
openapi: '3.0.0'
info:
  title: MPFH API
  version: '1.0'
servers:
  - url: https://YOUR_API_GATEWAY_ID.apigw.yandexcloud.net
paths:
  /save:
    post:
      x-yc-apigateway-integration:
        type: cloud_functions
        function_id: YOUR_FUNCTION_ID
        service_account_id: YOUR_SERVICE_ACCOUNT_ID
      operationId: saveData
      summary: Save replies data
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              properties:
                instruction:
                  type: string
                replies:
                  type: array
                  items:
                    type: string
      responses:
        '200':
          description: Data saved successfully
  /:
    get:
      x-yc-apigateway-integration:
        type: cloud_functions
        function_id: YOUR_FUNCTION_ID
        service_account_id: YOUR_SERVICE_ACCOUNT_ID
      operationId: getPage
      summary: Get HTML page with replies
      responses:
        '200':
          description: HTML page
```

Deploy API Gateway:

```bash
yc serverless api-gateway create \
  --name mpfh-api \
  --spec openapi.yaml
```

### 4. Update Frontend Config

Update `.env`:

```
VITE_API_URL=https://YOUR_API_GATEWAY_ID.apigw.yandexcloud.net
```

Rebuild frontend:

```bash
npm run build
```

### 5. Host Frontend

Options:
- Yandex Cloud Static Hosting
- Netlify / Vercel
- Any static file server

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `BUCKET_NAME` | S3 bucket name | `magic-show-data` |
| `PAGE_TITLE` | HTML page title | `MPFH — Ответы зрителей` |
| `VITE_API_URL` | API Gateway URL | Required |

## Troubleshooting

- **CORS errors**: Ensure API Gateway has `Access-Control-Allow-Origin: *` in responses
- **403 from S3**: Check service account has `editor` role on the bucket
- **Function timeout**: Increase `--execution-timeout` if processing large payloads
