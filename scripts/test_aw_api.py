import requests
import json

# Test the API
url = "https://www.americanwhitewater.org/api/v1/rivers?state=CO"

print(f"Testing API: {url}\n")

response = requests.get(url)
print(f"Status: {response.status_code}")

if response.status_code == 200:
    data = response.json()
    print(f"Got {len(data)} results\n")
    
    # Print first result to see structure
    if data:
        print("First result:")
        print(json.dumps(data[0], indent=2))
        
    # Save all data
    with open('test_api_response.json', 'w') as f:
        json.dump(data, f, indent=2)
    print("\nFull response saved to test_api_response.json")
else:
    print(f"Error: {response.text}")