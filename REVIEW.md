# RiverLog Feature Review

Stashed experimental features from `WIP: social features, permits, trips, maps, notifications`

To restore all: `git stash pop`
To view stash: `git stash show -p`
To selectively restore a file: `git checkout stash@{0} -- path/to/file`

---

## Features to Evaluate

### Social Features
- [ ] **Feed System** - FeedService, FeedActivity model, FeedActivityDetailView
- [ ] **User Profiles** - UserProfile model, UserProfileService, UserProfileView, EditProfileView, MyDetailedProfileView
- [ ] **Follow System** - FollowListView, SearchUsersView
- [ ] **Tagging** - TagUsersView
- [ ] **Groups** - GroupsView
- [ ] **Notifications** - NotificationService, NotificationsView

### Permits System
- [ ] **Permit Tracking** - PermitService, PermitAlertService
- [ ] **Permit Views** - PermitsView, PermitsContentView, PermitDetailView, PermitDiscoveryView, AddPermitView
- [ ] **RIDB Integration** - RIDBService (Recreation.gov API?)

### Trip Planning
- [ ] **Trip Management** - TripService, AddTripView, TripDetailView
- [ ] **Packing Lists** - TripPackingListView, PackingListTemplates
- [ ] **Camp Suggestions** - CampSpotSuggestionService

### Rivers & Maps
- [ ] **Rivers Map** - RiversMapViewModel, RiversMapViewRepresentable, RiversView
- [ ] **Section Details** - SectionDetailView, SectionPreviewCard, RiverSectionPopularityService
- [ ] **River Data** - river_paths.json, river_features.json

### Infrastructure / Utilities
- [ ] **Storage** - StorageService
- [ ] **Gauge Service** - GaugeService
- [ ] **Error Handling** - AppError
- [ ] **Logging** - Logger
- [ ] **Constants** - Constants.swift
- [ ] **Date Utilities** - DateUtilities
- [ ] **Profile Stats** - ProfileStatsCalculator

### Modified Existing Files
- [ ] Review changes to FirestoreService
- [ ] Review changes to GPSDataService, LocationManager
- [ ] Review changes to existing Views (ActivityDetailView, AddActivityView, etc.)
- [ ] Review Theme updates
- [ ] Review Core Data model changes (v6-v14)

### Scripts
- [ ] scrape_features.py, scrape_paths.py
- [ ] add_coordinates.py, merge_coordinates.py
- [ ] Updated scrape_aw.py

---

## Decision Log

| Feature | Decision | Notes |
|---------|----------|-------|
| | | |

---

## Next Steps
1. Review each feature category above
2. Mark [x] for features to keep, [-] for features to discard
3. For keepers, selectively restore from stash and commit properly
