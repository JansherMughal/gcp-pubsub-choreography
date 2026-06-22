#!/bin/bash
# Example API calls for testing the choreography flow
# Run from project root: bash examples/curl-test.sh

set -e

# Get API URL
cd terraform
API_URL=$(terraform output -raw orders_api_url)
cd ..

echo "=== Event-Driven Choreography API Test ==="
echo "API URL: $API_URL"
echo ""

# 1. Place order
echo "1️⃣  PLACE ORDER..."
RESPONSE=$(curl -s -X POST "$API_URL/orders" \
  -H 'Content-Type: application/json' \
  -d '{
    "restaurant_id": "food-in",
    "customer": { "email": "test@example.com" },
    "items": ["burger", "fries"]
  }')

ORDER_ID=$(echo $RESPONSE | grep -o '"order_id":"[^"]*' | cut -d'"' -f4)
echo "Response: $RESPONSE"
echo "Order ID: $ORDER_ID"
echo ""

# 2. Check order status
sleep 2
echo "2️⃣  CHECK ORDER STATUS..."
curl -s "$API_URL/orders/$ORDER_ID" | jq .
echo ""

# 3. Accept order
echo "3️⃣  ACCEPT ORDER..."
curl -s -X POST "$API_URL/orders/$ORDER_ID/accept" | jq .
echo ""

# 4. Check status again
sleep 2
echo "4️⃣  CHECK ORDER STATUS..."
curl -s "$API_URL/orders/$ORDER_ID" | jq .
echo ""

# 5. Complete order
echo "5️⃣  COMPLETE ORDER..."
curl -s -X POST "$API_URL/orders/$ORDER_ID/complete" | jq .
echo ""

# 6. Final status
echo "6️⃣  FINAL ORDER STATUS..."
curl -s "$API_URL/orders/$ORDER_ID" | jq '.events'
echo ""

echo "✅ Choreography test complete!"
