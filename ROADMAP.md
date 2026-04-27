# RiverLog Roadmap

## Primary Users
1. **Me** - guide (private + commercial)
2. **Beta tester** - boating friends (private and commercial boaters; hard and soft boats)
3. **Eventually** - broader paddling community and outfitters

---

## Strategy

Three paths that build on each other:

**Path 1: Personal Tool** (Phases 1-4)
Best activity tracker for guides and boaters. Custom sections, gear, stats, mileage exports.

**Path 2: B2B / Guide Management** (Phase 5+)
Outfitter dashboards, verified mileage sharing, CPW integration. Built-in beta tester (my partner).

**Path 3: Community Platform** (Later)
Subreddit-style communities, stream keepers, hazard reports, finding paddling partners.

```
Path 1 (Personal) → Path 2 (B2B) → Path 3 (Community)
```

**Now:** Path 1. Build personal tool features with B2B in mind:
- Private vs commercial trips → feeds outfitter dashboard
- Shareable mileage exports → becomes verified profile
- Cert storage → companies see guide credentials
- Section checkouts → "who's qualified" dashboard view

---

## App Structure (Strava-inspired)

Five tabs, modeled after Strava:

### Home
Your feed and activity snapshot.
- **Now:** Recent activities, basic streak
- **Later:** Feed from people you follow, suggested sections, weekly snapshot, goals

### Sections
Browse and discover river sections (like Strava's Maps tab).
- **Now:** Coming Soon (section picker exists but not as standalone tab)
- **Later:** Interactive map (AW-style), search/filter, flow status, favorites, "suggested for you"

### Record
GPS tracking for logging runs.
- **Now:** Working - section picker, live tracking, route playback
- **Later:** Faster logging workflow, auto-capture weather

### Groups
Social and work connections.
- **Now:** Coming Soon
- **Later:** Paddling crews (social), companies you work for (B2B), challenges

### You
Profile, stats, gear, activities.
- **Now:** Basic profile, stats, gear (boats only), activity history
- **Later:** Progress views (calendar, graphs), certs/docs, public profile, trophy case

---

## Current State (GPS Tracking Build - commit 207473c)
- [x] Activity logging with GPS tracking (works offline)
- [x] Live tracking + route playback
- [x] Firebase auth + cloud sync
- [x] Gear management (boats/crafts only)
- [x] USGS river data / section picker
- [x] Colorado rivers database
- [x] Basic stats

---

## Phase 1: Core Improvements

### Custom Sections → *Sections tab*
*"I ran Ruby to Hecla, not the whole Fish to Stone section"*
- [x] Define custom put-in / take-out within existing sections
- [x] Save custom sections for reuse
- [ ] Auto-calculate accurate mileage for the actual run
- [ ] Pull gauge from parent section
- [ ] Option to contribute to community section DB

### Full Gear Tracking → *You tab*
- [ ] Expand beyond boats: helmets, PFDs, paddles, drysuits, throw bags, etc.
- [ ] Gear categories
- [ ] Link any gear to activities

### Mile/Feature Annotations → *Record tab / Sections tab*
- [ ] Add notes at specific points during or after a run
- [ ] Hazard reporting: "strainer at mile 4", "new hole at #6"
- [ ] Personal notes vs community-visible hazards

---

## Phase 2: Trip Planning & Safety

### Multi-day Trip Model → *Record tab / You tab*
- [ ] Link multiple days/sections into one trip
- [ ] Campsite waypoints
- [ ] Packing lists (templates + custom)
- [ ] Permits tracking (which needed, dates, lottery deadlines)
- [ ] Logistics notes

### Live Location Sharing → *Record tab*
- [ ] Strava Beacon-style sharing while on water
- [ ] Share link with emergency contact
- [ ] Status indicator (on water / off water)

### Incident & Accident Logging → *Sections tab*
- [ ] Log personal incidents
- [ ] Scrape/aggregate online incident reports (AW, etc.)
- [ ] Per-section incident history

---

## Phase 3: Notifications & Widgets

### Flow Notifications → *Sections tab / iOS notifications*
- [ ] AW levels: runnable / unrunnable / high / low / outside commercial regs
- [ ] Custom threshold alerts ("notify me when X hits Y cfs")

### Home Screen Widget → *iOS widget*
- [ ] Flow for favorite sections
- [ ] Weather conditions
- [ ] Glanceable, no app open needed

### Weather Integration → *Record tab / Sections tab*
- [ ] Attach weather to activities (historical: "it was pouring")
- [ ] Weather forecast for trip planning

---

## Phase 4: Guide Tools

### Documents & Certifications → *You tab*
- [ ] Store certs: SWR, first aid, guide license, etc.
- [ ] Expiration date reminders
- [ ] Export all docs for company applications

### Mileage Export & Filtering → *You tab*
- [ ] Filter activities by class, river, date range
- [ ] Export proof of runs (e.g., "40 class 4+ runs" for Upper Gauley permit)
- [ ] Summary reports

---

## Phase 5: Social & Community

### User Profiles → *You tab*
- [ ] Bio, home river, craft type
- [ ] Public activity feed (opt-in)

### Trip Reports → *Home tab / Sections tab*
- [ ] Share trip reports with conditions, beta
- [ ] Flow reports from recent runs

### Section Discussions → *Sections tab*
- [ ] Per-section message board / comments
- [ ] Recent conditions, hazard updates

### Following → *Home tab / Groups tab*
- [ ] Follow other paddlers
- [ ] See their public trips/reports

---

## Phase 6: Stats & Media

### Year in Review / Cumulative Stats → *You tab*
- [ ] Total miles, days on water, rivers visited
- [ ] Year-over-year comparison
- [ ] Personal records

### Photos → *Record tab / You tab*
- [ ] Attach photos to activities
- [ ] (Deferred due to Firebase storage costs)

### Offline Section Data → *Sections tab*
- [ ] Cache section info for no-service put-ins
- [ ] Offline maps (?)

---

## Future: Enterprise / B2B

Not a separate app - a business layer that connects to boater accounts.

### The Model
- Guides use the personal app to track their runs (what we're building now)
- Guides opt-in to share data with companies they work for
- Outfitters get a dashboard view into their guide roster

### Outfitter Dashboard
- See guide mileage, certs, availability
- "Rebecca hasn't worked in 3 weeks" / "Jake's SWR expires next month"
- Assign guides to trips based on actual experience ("who's run Westwater 10+ times?")
- Guides accept/decline assignments in their personal app

### Shareable Guide Profile
- One-tap share verified mileage with outfitters (instead of emailing spreadsheets)
- Verified data - harder to fake than a self-reported resume
- Could work for hiring: share RiverLog profile, company sees everything

### CPW Integration
- Generate CPW-formatted mileage reports
- Direct API integration if CPW has one (need to research)
- At minimum: export exactly what they need in their format

### Other Outfitter Needs
- Shuttle logistics (vehicles, drivers, routes, timing)
- Staff scheduling & trip assignment
- Customer manifests & waivers
- Equipment fleet management
- Commercial permit tracking & compliance
- Multi-trip daily coordination
- Payroll / tip tracking

Outfitters currently run on spreadsheets, whiteboards, and group texts.

---

## Open Questions
- [ ] Custom sections: child of parent section, or independent entity?
- [ ] Trip reports: public by default or opt-in?
- [ ] Message board structure: per-section? per-river? regional?
- [ ] Enterprise: same app with tiers, or separate product?

---

## Stashed Work
Previous experimental code is in `git stash`. Quality unknown - review carefully before using:
```bash
git stash list                              # see stashes
git stash show --name-only                  # see files in stash
git stash show -p                           # see full diff
git checkout stash@{0} -- path/to/file      # grab specific file
```

Attempted features (may be salvageable):
- Social feed / followers / user profiles
- Permits system
- Trip planning with packing lists
- Maps view
- Notifications

---

## Ideas (Unsorted)
Drop new ideas here as they come up:

### From guide user story walkthrough
- Training hours tracking (CO requires 50 hours as rookie, paperwork submitted to CPW)
- Checkout status per section - which sections am I checked out on? (per company?)
- Auto-capture CFS at time of trip (don't make me remember)
- Private vs commercial trip distinction (TL requires 500 miles, half commercial)
- Career progression tracking (TL, class 4 guide, instructor - each has requirements)
- State-specific guide requirements (each state is different, need to research)
- Faster logging workflow - current one is slow so I skip details
- Section aliases already use AW data but need to verify normalization works
- Auto-capture CFS - already exists

### Social / Community ideas (Path 2 stuff)
- Find paddling partners beyond your work groupchat ("who wants to run X this weekend?")
- Buy/sell/trade gear marketplace
- Reddit-like forum (broader discussion, not just per-section)
- Joinable communities like subreddits ("Yough Boaters", "Colorado Guides")
- Communities tag sections - new hazards show on community home feed
- Follow sections directly - gauge + recent hazards on section page
- Optional notifications for followed sections
- Stream keeper model (like AW) - trusted users edit section info
- Pin useful links to sections (dam releases, permits) - can't scrape everything but can link
- Wikipedia-style community edits with moderation
