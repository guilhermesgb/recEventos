# =============================================================================
#   view_prepare_tables.R
#   Copyright (C) 2013  Augusto Queiroz
# 
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
# 
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
# 
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.
# =============================================================================
# Generate an optimized file distribution to minimize the amount of computation 
# by the view
# This is the final model:
# <CITY>/MEMBERs c("member_id", "member_lat", "member_lon", "member_name", 
#                  "member_city", "all_event_ids")
# <CITY>/EVENTS c("event_id", "event_name", "event_created", "event_time", 
#                 "event_venue_lat", "event_venue_lon", "event_venue_name")
# Every city directory will contain the members of that city and all events these 
# members went to
# =============================================================================

rm(list = ls())
source("src/rCode/common.R")

# Read the Member Events (already filtered)
cat("Read the Member Events (already filtered)\n")
member.events <- ReadAllCSVs(dir="data_output/partitions/", obj_name="member_events")
cat("Delete the rsvp.time in the Member Events\n")
member.events$rsvp_time <- NULL

# Read and select the EVENTs
cat("Read and select the events\n")
events <- ReadAllCSVs(dir="data_csv/", obj_name="events")[, c("id", "name", "created", "time", "venue_id")]
colnames(events) <- c("event_id", "event_name", "event_created", "event_time", "venue_id")


# Read and select the VENUEs
cat("Read and select the events\n")
venues <- ReadAllCSVs(dir="data_csv/", obj_name="venues")[, c("id", "lat", "lon", "name", "city")]
venues <- venues[venues$id %in% unique(events$venue_id),]
colnames(venues) <- c("venue_id", "venue_lat", "venue_lon", "venue_name", "venue_city")


# Read and select the MEMBERs
cat("Read and select the members\n")
members <- ReadAllCSVs(dir="data_csv/", obj_name="members")[, c("id", "lat", "lon", "name", "city")]
members <- members[members$id %in% unique(member.events$member_id),]
colnames(members) <- c("member_id", "member_lat", "member_lon", "member_name", "member_city")


# Read and select the PARTITIONs  (to be used by the selection of the 100 members)
cat("Read and select the partitions (just the first one)\n")
member.partitions <- ReadAllCSVs(dir="data_output/partitions/", obj_name="member_partitions")
member.partitions <- subset(member.partitions, partition == 1, c("member_id", "max_intersect_events"))

# Read the recommendation files
cat("Read the recommendation files: Distance Algorithm...\n")
rec.events.distance <- ReadAllCSVs("data_output/recommendations/", "rec_events_distance")
rec.events.distance$partition <- NULL
rec.events.distance$algorithm <- NULL
rec.events.distance <- rec.events.distance[order(rec.events.distance$member_id),]

cat("Read the recommendation files: Popularity Algorithm...\n")
rec.events.pop <- ReadAllCSVs("data_output/recommendations/", "rec_events_popularity")
rec.events.pop$partition <- NULL
rec.events.pop$algorithm <- NULL
rec.events.pop <- rec.events.pop[order(rec.events.pop$member_id),]

cat("Read the recommendation files: Popularity Algorithm...\n")
rec.events.topic <- ReadAllCSVs("data_output/recommendations/", "rec_events_topic")
rec.events.topic$partition <- NULL
rec.events.topic$algorithm <- NULL
rec.events.topic <- rec.events.topic[order(rec.events.topic$member_id),]

cat("Read the recommendation files: Popularity Algorithm...\n")
rec.events.weighted <- ReadAllCSVs("data_output/recommendations/", "rec_events_weighted")
rec.events.weighted$partition <- NULL
rec.events.weighted$algorithm <- NULL
rec.events.weighted <- rec.events.weighted[order(rec.events.weighted$member_id),]


# ------------------------------------------------------------------------------
# Visualization Constraint: The member_city should always be in venues_city, but
# the opposite is not right because there are 1956 venues with other venue_city
# names (the most with writing errors, just a few with no place) and they contain
# 10591 real events! Therefore, the venues and its events can't be discarded. 
#
# Obs.: We are not going to discard the venues explicitly but the processment of 
# spliting the venues by city will not add them to cities. They are going to be 
# used only when the member events or its recommendations were shown.
# ------------------------------------------------------------------------------
cat("Selecting the members with cities in the venues too...\n")
cities.intersect <- intersect(members$member_city, venues$venue_city)
members <- members[members$member_city %in% cities.intersect,]

# ------------------------------------------------------------------------------
# Select the 50 cities with more members (within the already selecte ones) 
# ------------------------------------------------------------------------------
cat("Select the 50 cities with more members (within the already selecte ones)...\n")
largest.member.cities <- count(members, "member_city")
largest.member.cities <- largest.member.cities[order(largest.member.cities$freq, 
                                                     decreasing=T),][1:50, "member_city"]

members <- subset(members, member_city %in% largest.member.cities)

# Re-Filter the member.events, the events, the venues and the partitions
member.events <- subset(member.events, member_id %in% members$member_id)
member.partitions <- subset(member.partitions, member_id %in% members$member_id)

# ------------------------------------------------------------------------------
# Prepare the MEMBERs and EVENTs tables to be persisted
# ------------------------------------------------------------------------------
# Merging the events with venues and excluding the venue
cat("Merging the EVENTs with VENUEs...\n")
events.with.venue <- merge(events, venues, by = "venue_id")[,c("event_id", "event_name", 
                                                               "event_created", "event_time",
                                                               "venue_lat", "venue_lon",
                                                               "venue_name", "venue_city")]
colnames(events.with.venue) <- c("event_id", "event_name", "event_created", "event_time",
                                 "event_venue_lat", "event_venue_lon", "venue_name", 
                                 "venue_city")
rm(venues)

# Selecting the Events of every Member
cat("Selecting the EVENTs of the MEMBERs...\n")
member.all.events <- ddply(idata.frame(member.events), .(member_id), function(m.events){
  data.frame(all_event_ids = paste(m.events$event_id, collapse = ","))
}, .progress = "text")

# Merging the Members with its Events
cat("Merging the EVENTs of the MEMBERs with the MEMBERs data...\n")
members <- merge(members, member.all.events, by = "member_id")

# Merging the Members with its max.intersect.events in Partition
cat("Merging the max.intersect.events of the MEMBERs with the MEMBERs data...\n")
members <- merge(members, member.partitions, by = "member_id")

rm(events, member.all.events, member.partitions)

# Selecting the Recommended Events per Member
cat("Collapsing the recommended event per algorithm...\n")
member.rec.events <- rec.events.distance[,c("member_id", "p_time")]

cat("  Distance...\n")
rec.events.distance$p_time <- NULL
member.rec.events$rec_events_distance <- ddply(rec.events.distance, .(member_id), function(m.rec.events){
  data.frame(events = paste(m.rec.events[,2:(ncol(m.rec.events))], collapse = ","))
}, .progress = "text")$events

cat("  Popularity...\n")
rec.events.pop$p_time <- NULL
member.rec.events$rec_events_pop <- ddply(rec.events.pop, .(member_id), function(m.rec.events){
  data.frame(events = paste(m.rec.events[,2:(ncol(m.rec.events))], collapse = ","))
}, .progress = "text")$events

cat("  Topic...\n")
rec.events.topic$p_time <- NULL
member.rec.events$rec_events_topic <- ddply(rec.events.topic, .(member_id), function(m.rec.events){
  data.frame(events = paste(m.rec.events[,2:(ncol(m.rec.events))], collapse = ","))
}, .progress = "text")$events

cat("  Weighted...\n")
rec.events.weighted$p_time <- NULL
member.rec.events$rec_events_weighted <- ddply(rec.events.weighted, .(member_id), function(m.rec.events){
  data.frame(events = paste(m.rec.events[,2:(ncol(m.rec.events))], collapse = ","))
}, .progress = "text")$events


# Merging the Rec_Event with the MEMBERs
cat("Merging the REC_EVENTs of all algorithms with the MEMBERs data...\n")
members <- merge(members, member.rec.events, by = "member_id")

rm(member.rec.events)

# -----------------------------------------------------------------------------
# PERSISTING ORGANIZEDLY
# -----------------------------------------------------------------------------
cat("Creating the directories...\n")
dir.create("data_output/view", showWarnings=F)
view.dir <- "data_output/view/optimized/"
dir.create(view.dir, showWarnings=F)

# Split the Members per City (50 cities only) and Apply the function in it
cat("Splitting by City and Persisting the MEMBER and VENUEs...\n")
d_ply(members, .(member_city), function(memb.df){
  city <- memb.df$member_city[1]
  
  # Create the city directory
  dir.create(paste(view.dir, city, sep = ""), showWarnings=F)
  
  # Select at most 100 members
  if (nrow(memb.df) > 100){
    memb.df <- memb.df[order(memb.df$max_intersect_events, decreasing = T),]
    memb.df <- memb.df[1:100,]
  }

  # Remove the max_intersect_events from members
  memb.df$max_intersect_events <- NULL
  
  # Select its events
  event.ids <- subset(member.events, member_id %in% memb.df$member_id)$event_id
  event.df <- subset(events.with.venue, event_id %in% event.ids)
  
  # Select rec events
  rec.event.ids <- unique(strsplit(paste(sapply(memb.df[,(ncol(memb.df) - 3) : ncol(memb.df)], 
                                                function(recs){paste(recs, collapse = ",")}), collapse = ","), ",")[[1]])
  rec.event.df <- subset(events.with.venue, event_id %in% rec.event.ids)
  
  # Persist the result
  write.csv(memb.df, paste(view.dir, city, "/members.csv", sep = ""), row.names = F)
  write.csv(event.df, paste(view.dir, city, "/events.csv", sep = ""), row.names = F)
  write.csv(rec.event.df, paste(view.dir, city, "/rec_events.csv", sep = ""), row.names = F)
  
}, .progress = "text")
