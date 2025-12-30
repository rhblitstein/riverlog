import requests
from bs4 import BeautifulSoup

url = "https://www.americanwhitewater.org/content/River/view/river-index/state/USA-COL"

response = requests.get(url, timeout=15)
soup = BeautifulSoup(response.content, 'html.parser')

# Print all links to see what we're working with
print("All links on the page:")
print("=" * 50)
for i, link in enumerate(soup.find_all('a', href=True)[:20]):  # First 20 links
    print(f"{i+1}. Text: '{link.get_text(strip=True)[:50]}'")
    print(f"   href: {link['href']}\n")

# Save full HTML for inspection
with open('debug_page.html', 'w') as f:
    f.write(soup.prettify())
print("\nFull HTML saved to debug_page.html")