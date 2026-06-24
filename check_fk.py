import urllib.request
import json

# We can query postgres information_schema via RPC if there's one, or we can see if we can do an insert into game.players first and see if settlement creation succeeds.
# Let's try inserting the user into game.players AND public.profiles, then see if settlement creation succeeds!
url_players = 'https://kjvfvttvdnjpomchwaoi.supabase.co/rest/v1/players'
url_settlements = 'https://kjvfvttvdnjpomchwaoi.supabase.co/rest/v1/settlements'
url_signup = 'https://kjvfvttvdnjpomchwaoi.supabase.co/auth/v1/signup'
anon_key = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtqdmZ2dHR2ZG5qcG9tY2h3YW9pIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk4MDA0MDQsImV4cCI6MjA5NTM3NjQwNH0.1_euqabF7oiUH3S2uVwaT2PCgK8iLuFGGbSVhYuDwnc'

import time
email = f"test_{int(time.time())}@example.com"
auth_data = {
    "email": email,
    "password": "password123",
    "data": {
        "display_name": "FK Test User"
    }
}

headers_base = {
    'apikey': anon_key,
    'Content-Type': 'application/json'
}

req_auth = urllib.request.Request(url_signup, headers=headers_base, data=json.dumps(auth_data).encode('utf-8'), method='POST')
try:
    with urllib.request.urlopen(req_auth) as response:
        auth_res = json.loads(response.read().decode('utf-8'))
        player_id = auth_res.get('id') or auth_res.get('user', {}).get('id')
        print("Signup Successful. player_id:", player_id)
        
        # Now let's try to insert into game.players to see if it succeeds
        headers_game = {
            'apikey': anon_key,
            'Authorization': f'Bearer {anon_key}',
            'Content-Type': 'application/json',
            'Accept-Profile': 'game',
            'Content-Profile': 'game'
        }
        player_row = {"id": player_id, "display_name": "FK Test User"}
        req_p = urllib.request.Request(url_players, headers=headers_game, data=json.dumps(player_row).encode('utf-8'), method='POST')
        try:
            with urllib.request.urlopen(req_p) as resp_p:
                print("Insert into game.players success!")
        except Exception as e_p:
            if hasattr(e_p, 'read'):
                print("Insert into game.players failed:", e_p.read().decode('utf-8'))
            else:
                print("Insert into game.players failed:", e_p)
                
        # Now let's try to insert into game.settlements
        settlement_row = {
            "player_id": player_id,
            "name": "FK Test Settlement",
            "map_x": 10,
            "map_y": 10
        }
        req_s = urllib.request.Request(url_settlements, headers=headers_game, data=json.dumps(settlement_row).encode('utf-8'), method='POST')
        try:
            with urllib.request.urlopen(req_s) as resp_s:
                print("Insert into game.settlements success!")
        except Exception as e_s:
            if hasattr(e_s, 'read'):
                print("Insert into game.settlements failed:", e_s.read().decode('utf-8'))
            else:
                print("Insert into game.settlements failed:", e_s)
except Exception as e:
    print("General Error:", e)
