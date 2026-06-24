import urllib.request
import json
import time

url_signup = 'https://kjvfvttvdnjpomchwaoi.supabase.co/auth/v1/signup'
url_profile = 'https://kjvfvttvdnjpomchwaoi.supabase.co/rest/v1/profiles'
anon_key = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtqdmZ2dHR2ZG5qcG9tY2h3YW9pIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk4MDA0MDQsImV4cCI6MjA5NTM3NjQwNH0.1_euqabF7oiUH3S2uVwaT2PCgK8iLuFGGbSVhYuDwnc'

# 1. Sign up test user
email = f"test_{int(time.time())}@example.com"
auth_data = {
    "email": email,
    "password": "password123",
    "data": {
        "display_name": "Test Python User"
    }
}

headers_auth = {
    'apikey': anon_key,
    'Content-Type': 'application/json'
}

req_auth = urllib.request.Request(url_signup, headers=headers_auth, data=json.dumps(auth_data).encode('utf-8'), method='POST')
try:
    with urllib.request.urlopen(req_auth) as response:
        res_body = response.read().decode('utf-8')
        auth_res = json.loads(res_body)
        print("Auth Signup Success:")
        print(json.dumps(auth_res, indent=2))
        
        player_id = auth_res.get('id') or auth_res.get('user', {}).get('id')
        print("Retrieved Player ID:", player_id)
        
        # 2. Check if profile exists
        headers_prof = {
            'apikey': anon_key,
            'Authorization': f'Bearer {anon_key}',
            'Accept-Profile': 'public'
        }
        url_get_profile = f"{url_profile}?id=eq.{player_id}"
        req_prof = urllib.request.Request(url_get_profile, headers=headers_prof)
        with urllib.request.urlopen(req_prof) as prof_response:
            prof_data = prof_response.read().decode('utf-8')
            print("Profile Check Response:")
            print(prof_data)
except Exception as e:
    if hasattr(e, 'read'):
        print("HTTP Error:", e.code, e.reason)
        print("Details:", e.read().decode('utf-8'))
    else:
        print("Error:", e)
