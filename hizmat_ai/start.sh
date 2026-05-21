#!/bin/bash
# HizmatAI quick-start script
set -e

echo "▶ Starting HizmatAI FastAPI backend..."
cd "$(dirname "$0")/backend"
pip install -r requirements.txt -q
uvicorn main:app --reload --port 8000 &
BACKEND_PID=$!
echo "  Backend PID: $BACKEND_PID — http://localhost:8000"

sleep 2
echo ""
echo "▶ Health check..."
curl -s http://localhost:8000/health | python3 -m json.tool

echo ""
echo "▶ Flutter app — run manually:"
echo "  cd flutter_app && flutter pub get && flutter run"
echo ""
echo "Press Ctrl+C to stop backend"
wait $BACKEND_PID
