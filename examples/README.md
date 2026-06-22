# Examples

## curl API Testing

Test the choreography flow without the browser UI:

```bash
bash curl-test.sh
```

This script:
1. Places an order (emits `order_placed`)
2. Checks order status
3. Accepts the order (emits `order_accepted`)
4. Checks status again
5. Completes the order (emits `order_completed`)
6. Shows final event log

## Manual Requests

### Place Order
```bash
curl -X POST https://YOUR_API_URL/orders \
  -H 'Content-Type: application/json' \
  -d '{
    "restaurant_id": "food-in",
    "customer": { "email": "user@example.com" },
    "items": ["burger"]
  }'
```

### Get Order Status
```bash
curl https://YOUR_API_URL/orders/ORDER_ID
```

### Accept Order
```bash
curl -X POST https://YOUR_API_URL/orders/ORDER_ID/accept
```

### Complete Order
```bash
curl -X POST https://YOUR_API_URL/orders/ORDER_ID/complete
```

## Getting Your API URL

```bash
cd terraform
terraform output orders_api_url
```
