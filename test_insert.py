import urllib.request
import json

url = 'https://kjvfvttvdnjpomchwaoi.supabase.co/rest/v1/settlements'
anon_key = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtqdmZ2dHR2ZG5qcG9tY2h3YW9pIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk4MDA0MDQsImV4cCI6MjA5NTM3NjQwNH0.1_euqabF7oiUH3S2uVwaT2PCgK8iLuFGGbSVhYuDwnc'

headers = {
    'apikey': anon_key,
    'Authorization': f'Bearer {anon_key}',
    'Accept-Profile': 'game',
    'Content-Profile': 'game',
    'Content-Type': 'application/json',
    'Prefer': 'return=representation'
}

# Try inserting a settlement with a random player_id uuid (it might fail due to FK or missing columns, let's see!)
# Let's generate a valid UUID for testing
data = {
    "player_id": "00000000-0000-0000-0000-000000000000",
    "name": "Test Settlement Error Check",
    "map_x": 50,
    "map_y": 50
}

req = urllib.request.Request(url, headers=headers, data=json.dumps(data).encode('utf-8'), method='POST')
try:
    with urllib.request.urlopen(req) as response:
        print("Success:", response.read().decode('utf-8'))
except Exception as e:
    if hasattr(e, 'read'):
        print("HTTP Error:", e.code, e.reason)
        print("Details:", e.read().decode('utf-8'))
    else:
        print("Error:", e)
