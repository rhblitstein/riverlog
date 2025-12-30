import requests
import json
import time
import urllib.parse
import re

# State codes
STATES = {
    'AK': 'USA-AK', 'AL': 'USA-AL', 'AR': 'USA-AR', 'AZ': 'USA-AZ',
    'CA': 'USA-CAL', 'CO': 'USA-COL', 'CT': 'USA-CT', 'DE': 'USA-DE',
    'FL': 'USA-FL', 'GA': 'USA-GA', 'HI': 'USA-HI', 'IA': 'USA-IA',
    'ID': 'USA-ID', 'IL': 'USA-IL', 'IN': 'USA-IN', 'KS': 'USA-KS',
    'KY': 'USA-KY', 'LA': 'USA-LA', 'MA': 'USA-MA', 'MD': 'USA-MD',
    'ME': 'USA-ME', 'MI': 'USA-MI', 'MN': 'USA-MN', 'MO': 'USA-MO',
    'MS': 'USA-MS', 'MT': 'USA-MT', 'NC': 'USA-NC', 'ND': 'USA-ND',
    'NE': 'USA-NE', 'NH': 'USA-NH', 'NJ': 'USA-NJ', 'NM': 'USA-NM',
    'NV': 'USA-NV', 'NY': 'USA-NY', 'OH': 'USA-OH', 'OK': 'USA-OK',
    'OR': 'USA-OR', 'PA': 'USA-PA', 'RI': 'USA-RI', 'SC': 'USA-SC',
    'SD': 'USA-SD', 'TN': 'USA-TN', 'TX': 'USA-TX', 'UT': 'USA-UT',
    'VA': 'USA-VA', 'VT': 'USA-VT', 'WA': 'USA-WA', 'WI': 'USA-WI',
    'WV': 'USA-WV', 'WY': 'USA-WY'
}

BASE_STATE_URL = "https://trpc-api.americanwhitewater.org/reach/stateView"
BASE_DETAIL_URL = "https://trpc-api.americanwhitewater.org/reach/reachDetail"

def fetch_state_sections(state_code, state_abbr):
    """Fetch all sections for a given state"""
    input_data = json.dumps({"0": {"json": {"state": state_code}}})
    encoded_input = urllib.parse.quote(input_data)
    url = f"{BASE_STATE_URL}?batch=1&input={encoded_input}"
    
    print(f"\nFetching {state_abbr} section list...")
    
    try:
        response = requests.get(url, timeout=30)
        response.raise_for_status()
        data = response.json()
        sections_data = data[0]['result']['data']['json']
        
        section_ids = [str(item['reach']['id']) for item in sections_data]
        print(f"Found {len(section_ids)} sections")
        return section_ids
        
    except Exception as e:
        print(f"Error fetching {state_abbr}: {e}")
        return []

def fetch_section_detail(section_id, state_abbr):
    """Fetch detailed info for a specific section"""
    input_data = json.dumps({"0": {"json": {"reachID": section_id}}})
    encoded_input = urllib.parse.quote(input_data)
    url = f"{BASE_DETAIL_URL}?batch=1&input={encoded_input}"
    
    try:
        response = requests.get(url, timeout=30)
        response.raise_for_status()
        data = response.json()
        
        reach_data = data[0]['result']['data']['json']
        stub = reach_data.get('stub', {})
        detail = reach_data.get('detail', {})
        
        # Get put-in and take-out from pointOfInterests
        pois = reach_data.get('pointOfInterests', [])
        put_in = next((p['name'] for p in pois if p.get('type') == 'put-in'), '')
        take_out = next((p['name'] for p in pois if p.get('type') == 'takeout'), '')
        
        # Get gauge info from correlations
        correlations = detail.get('correlations', [])
        gauge_name = ''
        gauge_id = ''
        if correlations:
            gauge_info = correlations[0].get('gaugeInfo', {})
            gauge_name = gauge_info.get('name', '')
            gauge_id = gauge_info.get('gaugeSourceIdentifier', '')
        
        # Clean up section name
        section_name = stub.get('section', '')
        section_name_clean = re.sub(r'^\d+\.\s*', '', section_name)
        
        section = {
            'id': section_id,
            'name': section_name_clean,
            'riverName': stub.get('river', ''),
            'state': state_abbr,
            'classRating': stub.get('difficulty', ''),
            'gradient': float(detail.get('averageGradient', 0)) if detail.get('averageGradient') else None,
            'gradientUnit': 'fpm',
            'mileage': float(detail.get('length', 0)) if detail.get('length') else None,
            'putInName': put_in,
            'takeOutName': take_out,
            'gaugeName': gauge_name,
            'gaugeID': gauge_id,
            'awURL': f"https://www.americanwhitewater.org/content/River/detail/id/{section_id}"
        }
        
        print(f"  ✓ {section['riverName']}: {section['name']}")
        return section
        
    except Exception as e:
        print(f"  ✗ Error fetching section {section_id}: {e}")
        return None

def main():
    print("American Whitewater API Scraper")
    print("=" * 50)
    print("Fetching detailed section data with gradient, mileage, and gauge info")
    print()
    
    all_sections = []
    
    # For testing, just do Colorado
    # Change to STATES to do all states
    test_states = {'CO': 'USA-COL'}
    
    for state_abbr, state_code in test_states.items():
        # Get list of section IDs
        section_ids = fetch_state_sections(state_code, state_abbr)
        
        # Fetch details for each section
        print(f"Fetching details for {len(section_ids)} sections...")
        for i, section_id in enumerate(section_ids, 1):
            section = fetch_section_detail(section_id, state_abbr)
            if section:
                all_sections.append(section)
            
            # Progress indicator
            if i % 50 == 0:
                print(f"  Progress: {i}/{len(section_ids)}")
            
            # Be nice to their servers
            time.sleep(0.5)
    
    print(f"\n{'=' * 50}")
    print(f"Successfully scraped {len(all_sections)} sections")
    
    # Save to JSON
    output_file = "river_sections.json"
    with open(output_file, 'w') as f:
        json.dump(all_sections, f, indent=2)
    
    print(f"Saved to {output_file}")
    
    # Show some stats
    with_gradient = sum(1 for s in all_sections if s['gradient'])
    with_mileage = sum(1 for s in all_sections if s['mileage'])
    with_gauge = sum(1 for s in all_sections if s['gaugeID'])
    
    print(f"\nStats:")
    print(f"  Sections with gradient: {with_gradient}/{len(all_sections)}")
    print(f"  Sections with mileage: {with_mileage}/{len(all_sections)}")
    print(f"  Sections with gauge: {with_gauge}/{len(all_sections)}")
    
    print("\nSample sections:")
    for section in all_sections[:5]:
        print(f"  - {section['riverName']}: {section['name']}")
        print(f"    Class {section['classRating']}, {section['mileage']} mi, {section['gradient']} fpm")
        if section['gaugeID']:
            print(f"    Gauge: {section['gaugeName']} ({section['gaugeID']})")

if __name__ == "__main__":
    main()