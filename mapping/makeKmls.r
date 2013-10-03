library("maptools")
library("rgeos")

incidentsClasses <- structure(c("character", "character", "factor", "factor", "integer", 
"factor", "integer", "factor", "numeric", "numeric"), .Names = c("DateOfCall", 
"TimeOfCall", "IncidentGroup", "IncidentStationGround", "FirstPumpArriving_AttendanceTime", 
"FirstPumpArriving_DeployedFromStation", "SecondPumpArriving_AttendanceTime", 
"SecondPumpArriving_DeployedFromStation", "latitude", "longitude"
))
incidents <- read.csv("incidents.csv", header = TRUE, sep = ',', colClasses = incidentsClasses, na.strings = 'NULL')

stationsClasses <- structure(c("factor", "character", "numeric", "numeric"), .Names = c("name", "address", "latitude", "longitude"))
stations <- read.csv("stations.csv", header = TRUE, sep = ',', colClasses = stationsClasses, na.strings = 'NULL')

# I keep only the incidents to which the first pump to arrive was the station 
# ground's and attendance time was withing the target 6 minutes; I presume that
# the polygon represented by the remaining set of incidents is a good 
# approximation of the geographical area that can be served by the station in 
# six minutes. I also drop the columns that are not required in the following.
reachAsFirstPumpArriving <- subset(incidents, FirstPumpArriving_AttendanceTime <= 360, c('FirstPumpArriving_DeployedFromStation', 'FirstPumpArriving_AttendanceTime', 'longitude', 'latitude'))
colnames(reachAsFirstPumpArriving) <- c("station", "attendanceTime", "longitude", "latitude")
reachAsSecondPumpArriving <- subset(incidents, SecondPumpArriving_AttendanceTime <= 360, c('SecondPumpArriving_DeployedFromStation', 'FirstPumpArriving_AttendanceTime', 'longitude', 'latitude'))
colnames(reachAsSecondPumpArriving) <- c("station", "attendanceTime", "longitude", "latitude")
reach <- rbind(reachAsFirstPumpArriving, reachAsSecondPumpArriving)

for (s in levels(reach$station)) {
	sourceStation <- subset(stations, name == s, c('longitude', 'latitude'))[1,]
	reachStation <- subset(reach, station == s, c('longitude', 'latitude'))
	temp <- reachStation[rep(1:nrow(reachStation), 1, each = 2), ]
	reachStation[seq(1, nrow(temp) + 1, 2), 1:2] <- sourceStation
	# TODO: the line below fails unless I heavily constrain the number of 
	# incidents I create the LINESTRING from. I believe that the problem is a
	# string too long to be manageable by either geos or R itself. But how
	# can I create the line otherwise?
	line = readWKT(paste("LINESTRING(", paste(apply(reachStation[1:21, ], 1, paste, collapse = " "), collapse = ","), ")"))
	# I have tested experimentally that a 0.0006 buffer width corresponds to
	# about 100 meters diameter
	area = gBuffer(line, width = 0.0006, capStyle = "ROUND")
	kmlPolygon(area@polygons[[1]], kmlfile = paste("maps/", s, ".kml", sep = ""), name = s, col = "#df0000aa", lwd = 5, border = 4, kmlname = s, kmldescription = "")
}

#	reachStation <- subset(reach, station == s, c('longitude', 'latitude'))
#	reachVertices <- chull(reachStation)
#	reachPolygons <- Polygons(list(Polygon(reachStation[c(reachVertices, reachVertices[1]), ])), "1")
#	kmlPolygon(reachPolygons, kmlfile = paste("maps/", s, ".kml", sep = ""), name = s, col = "#df0000aa", lwd = 5, border = 4, kmlname = s, kmldescription = "")
