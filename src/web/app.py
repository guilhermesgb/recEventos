"""
   app.py - RecEventos server side
   Copyright (C) 2013  Guilherme Santos
 
   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.
 
   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.
 
   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <http://www.gnu.org/licenses/>.
"""

from flask import Flask, render_template
import os, json, string, time, csv


DEBUG = True
SECRET_KEY = 'dev_key'

app = Flask(__name__)
app.config.from_object(__name__)

def read_events_and_members(city):

	events = []
	with open(os.path.join("src", "web", "files", city, "events.csv"), 'r') as source:
		csv_reader = csv.reader(source)
		csv_reader.next()
		for event in csv_reader:
			events.append({ 'id' : event[0].strip(),
				'name' : filter(lambda x: x in string.printable, event[1]).strip().encode('utf8').replace("\\", ""),
				'created' : time.asctime(time.localtime(float(event[2].strip())/1000)).encode('utf8'),
				'time' : time.asctime(time.localtime(float(event[3].strip())/1000)).encode('utf8'),
				'lat' : event[4].strip(),
				'lon' : event[5].strip(),
				'venue_name' : filter(lambda x: x in string.printable, event[6]).strip().encode('utf8').replace("\\", ""),
				'venue_city' : filter(lambda x: x in string.printable, event[7]).strip().encode('utf8').replace("\\", ""),
				'time_long' : event[3].strip(),
				'created_long' : event[2].strip()
				})

	print "Loaded "+str(len(events))+" events from ", city

	rec_events = []
	with open(os.path.join("src", "web", "files", city, "rec_events.csv"), 'r') as source:
		csv_reader = csv.reader(source)
		csv_reader.next()
		for rec_event in csv_reader:
			rec_events.append({'id' : rec_event[0].strip(),
				'name' : filter(lambda x: x in string.printable, rec_event[1]).strip().encode('utf8').replace("\\", ""),
				'created' : time.asctime(time.localtime(float(rec_event[2].strip())/1000)).encode('utf8'),
				'time' : time.asctime(time.localtime(float(rec_event[3].strip())/1000)).encode('utf8'),
				'lat' : rec_event[4].strip(),
				'lon' : rec_event[5].strip(),
				'venue_name' : filter(lambda x: x in string.printable, rec_event[6]).strip().encode('utf8').replace("\\", ""),
				'venue_city' : filter(lambda x: x in string.printable, rec_event[7]).strip().encode('utf8').replace("\\", ""),
				'time_long' : rec_event[3].strip(),
				'created_long' : rec_event[2].strip()
				})

	print "Loaded "+str(len(rec_events))+" recommended events from ", city

	user_names = {}
	users = []
	with open(os.path.join("src", "web", "files", city, "members.csv"), 'r') as source:
		csv_reader = csv.reader(source)
		csv_reader.next()
		for user in csv_reader:
			#user[0] - id; user[3] - name; user[2] - longitude; user[1] - latitude
			user[3] = user[3].split(" ")[0].capitalize()
			if not user[3] in user_names:
				user_names[user[3]] = 0
			user_names[user[3]] += 1
			suffix = ""
			if ( user_names[user[3]] > 1 ):
				suffix = "_" + str(user_names[user[3]])
			user_info = { 'id' : user[0].strip(),
					'name' : filter(lambda x: x in string.printable, user[3] + suffix).strip().encode('utf8').replace("\\", ""),
					'lon' : user[2].strip(),
					'lat' : user[1].strip(),
					'city' : filter(lambda x: x in string.printable, user[4]).strip().encode('utf8').replace("\\", ""),
					'p_time' : user[6],
					'rec_distance' : user[7],
					'rec_popularity' : user[8],
					'rec_topics' : user[9],
					'rec_weighted' : user[10]}

			user_info["events"] = user[5]
			users.append( user_info )
			
	print "Loaded "+str(len(users))+" users from ", city

	return ( events, rec_events, users )

@app.route('/')
def index():

	r = read_events_and_members("Arlington")
	events = r[0]
	rec_events = r[1]
	users = r[2]

	cities = [ "Addison", "Allen", "Arlington", "Bedford", "Berkeley", "Burlingame",
"Campbell", "Carlsbad", "Carrollton", "Chula Vista", "Cupertino", "Dallas",
"Dublin", "El Cajon", "Encinitas", "Escondido", "Euless", "Flower Mound",
"Fort Worth", "Fremont", "Frisco", "Garland", "Grapevine",
"Irving", "La Jolla", "La Mesa", "Lewisville", "Los Altos", "Los Gatos",
"Menlo Park", "Milpitas", "Mountain View", "Oakland", "Oceanside", "Palo Alto",
"Plano", "Pleasanton", "Poway", "Redwood City", "Richardson", "San Carlos",
"San Diego", "San Francisco", "San Jose", "San Mateo", "San Ramon",
"Santa Clara", "Santa Cruz", "Sunnyvale" ]

	print "index will send data now"
	return render_template("index.html", users=users, events=events, cities=cities, rec_events=rec_events)

@app.route('/load_city/<city>')
def load_city(city=None):

	r = read_events_and_members(city.replace("_", " "))
	events = r[0]
	rec_events = r[1]
	users = r[2]

	print "load city will send data now"
	return json.dumps({ 'events' : events, 'users' : users, 'rec_events' : rec_events })

if __name__ == "__main__":
	port = int(os.environ.get('PORT', 5000))
	app.run(host='0.0.0.0', port=port, debug=True)
