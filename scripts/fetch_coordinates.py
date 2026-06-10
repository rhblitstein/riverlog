"""
Fetch put-in and take-out coordinates for all river sections from AW API.
Updates river_sections.json with lat/lng data.
"""

import requests
import json
import time
import urllib.parse

BASE_DETAIL_URL = "https://trpc-api.americanwhitewater.org/reach/reachDetail"

def fetch_coordinates(section_id):
    """Fetch put-in and take-out coordinates for a section from AW API.
    Uses the geometry LineString: first coord = put-in, last coord = take-out."""
    input_data = json.dumps({"0": {"json": {"reachID": str(section_id)}}})
    encoded_input = urllib.parse.quote(input_data)
    url = f"{BASE_DETAIL_URL}?batch=1&input={encoded_input}"

    try:
        response = requests.get(url, timeout=30)
        response.raise_for_status()
        data = response.json()

        reach_data = data[0]['result']['data']['json']
        detail = reach_data.get('detail', {})
        geom = detail.get('geometry')

        put_in_lat = None
        put_in_lng = None
        take_out_lat = None
        take_out_lng = None

        # Primary: use geometry LineString (first coord = put-in, last = take-out)
        if geom and isinstance(geom, dict) and geom.get('type') == 'LineString':
            coords = geom.get('coordinates', [])
            if len(coords) >= 2:
                # GeoJSON is [longitude, latitude]
                put_in_lng = coords[0][0]
                put_in_lat = coords[0][1]
                take_out_lng = coords[-1][0]
                take_out_lat = coords[-1][1]

        # Fallback: check POIs for non-zero coordinates
        if not put_in_lat:
            pois = reach_data.get('pointOfInterests', [])
            for poi in pois:
                poi_type = poi.get('type', '').lower()
                loc = poi.get('location', {})
                lat = float(loc.get('latitude', 0))
                lng = float(loc.get('longitude', 0))

                if lat != 0 and lng != 0:
                    if 'put-in' in poi_type or 'putin' in poi_type:
                        put_in_lat = lat
                        put_in_lng = lng
                    elif 'take' in poi_type or 'takeout' in poi_type:
                        take_out_lat = lat
                        take_out_lng = lng

        return {
            'putInLatitude': put_in_lat,
            'putInLongitude': put_in_lng,
            'takeOutLatitude': take_out_lat,
            'takeOutLongitude': take_out_lng
        }

    except Exception as e:
        print(f"  ✗ Error fetching coordinates for section {section_id}: {e}")
        return None


def main():
    # Load existing sections
    input_file = "river_sections.json"
    with open(input_file, 'r') as f:
        sections = json.load(f)

    print(f"Fetching coordinates for {len(sections)} sections...")
    print("=" * 50)

    updated = 0
    failed = 0

    for i, section in enumerate(sections, 1):
        section_id = section['id']
        coords = fetch_coordinates(section_id)

        if coords and (coords['putInLatitude'] or coords['takeOutLatitude']):
            section['putInLatitude'] = coords['putInLatitude']
            section['putInLongitude'] = coords['putInLongitude']
            section['takeOutLatitude'] = coords['takeOutLatitude']
            section['takeOutLongitude'] = coords['takeOutLongitude']
            updated += 1
            print(f"  ✓ [{i}/{len(sections)}] {section['riverName']}: {section['name']} — ({coords['putInLatitude']}, {coords['putInLongitude']})")
        else:
            failed += 1
            print(f"  ✗ [{i}/{len(sections)}] {section['riverName']}: {section['name']} — no coords found")

        # Be nice to their servers
        time.sleep(0.4)

        # Save progress every 50 sections
        if i % 50 == 0:
            with open(input_file, 'w') as f:
                json.dump(sections, f, indent=2)
            print(f"\n  💾 Saved progress ({i}/{len(sections)})\n")

    # Final save
    with open(input_file, 'w') as f:
        json.dump(sections, f, indent=2)

    print(f"\n{'=' * 50}")
    print(f"Done! Updated {updated} sections, {failed} without coordinates.")
    print(f"Saved to {input_file}")


if __name__ == "__main__":
    main()
