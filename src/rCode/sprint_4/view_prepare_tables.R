rm(list = ls())
source("src/rCode/common.R")

# Read the Member Events (already filtered)
cat("Read the Member Events (already filtered)")
member.events <- ReadAllCSVs(dir="data_output/partitions/", obj_name="member_events")

# Delete the event.time in the member.events
cat("Delete the event.time in the member.events")
member.events$event_time <- NULL

# Read and select the events
cat("Read and select the events")
events <- ReadAllCSVs(dir="data_csv/", obj_name="events")[, c("id", "name", "venue_id", "time")]
events <- events[events$id %in% unique(member.events$event_id),]
colnames(events) <- c("event_id", "event_name", "venue_id", "event_time")

# Read and select the venues
cat("Read and select the events")
venues <- read.csv("data_csv/venues.csv")[, c("id", "lat", "lon", "name", "city")]
venues <- venues[venues$id %in% unique(events$venue_id),]
colnames(venues) <- c("venue_id", "venue_lat", "venue_lon", "venue_name", "venue_city")

# Read and select the members
cat("Read and select the members")
members <- ReadAllCSVs(dir="data_csv/", obj_name="members")[, c("id", "lat", "lon", "name", "city")]
members <- members[members$id %in% unique(member.events$member_id),]
# Select the members with cities in the venues_city column (visualization constraint)
members <- members[members$city %in% unique(venues$venue_city),]
colnames(members) <- c("member_id", "member_lat", "member_lon", "member_name", "member_city")

# Persist in data_view
cat("Persist the data")
dir.create("data_output/view/", showWarnings=F)
write.csv(members,"data_output/view/members.csv", row.names = F)
write.csv(events,"data_output/view/events.csv", row.names = F)
write.csv(venues,"data_output/view/venues.csv", row.names = F)
write.csv(member.events,"data_output/view/member_events.csv", row.names = F)