### Merlin Polygon Pack Builder ###
### by Gates Dupont             ###
### February 2018               ###
###################################

########
"INPUTS"
########

##############################################################################

KML = "AmazonRainforest.kml"
Layer = "AmazonRainforest" # Not sure? See ogrInfo(KML)
APIkey = "{{merlin-user-key}}"
file = "Untitled layer"

##############################################################################

########
"CODE"
########

library(jsonlite)
library(rgdal)
library(sp)
library(maptools)
library(leaflet)

###--------------FUNCTIONS------------------

# FUNCTION: 
# Pull from internal API
freq.API.pull = function(lat, lng){
  url = paste("https://ebird.org/ws2.0/product/geo/freqlist?lat=", 
              lat, "&lng=", lng, "&key=", APIkey, sep = "")
  data = fromJSON(readLines(url, warn=FALSE))
  return(data)
}


###--------------POLYGON GRID--------------------

# Importing KML file and setting projection // drawn in Google Earth)
my.poly = readOGR(ds = KML, layer = Layer)
proj4string(my.poly) <- "+proj=longlat +datum=WGS84 +no_defs"
spTransform(my.poly, CRS("+proj=longlat +datum=WGS84 +no_defs"))

# Creating grid of points // n = (# points)
grdpts = makegrid(my.poly, n = 10)

# Converting from df to spdf
coords = cbind(grdpts$x1, grdpts$x2)
sp = SpatialPoints(coords)
proj4string(sp) <- CRS(proj4string(my.poly)) # spdf = SpatialPointsDataFrame(coords, grdpts, proj4string = CRS(proj4string(my.poly)))

# Selecting only points in the polygon
poly.points = sp[complete.cases(over(sp,my.poly))]

###-----------CHECK: PLOTTING POLYGON AND POINTS ---------------

# Plotting the points
leaflet(my.poly) %>% addProviderTiles(providers$CartoDB.Positron) %>%
  addPolygons(color = "orange") %>%
  addCircleMarkers(lat = poly.points@coords[,"coords.x2"], 
                   lng = poly.points@coords[,"coords.x1"],
                   color = "blue" ,radius = 0.8)

###--------------PULLING FREQUENCY FROM GRID--------------------

allData = data.frame()
for(i in (1:length(poly.points@coords[,"coords.x1"]))){
  allData = rbind(allData, freq.API.pull(lat = poly.points@coords[,"coords.x2"][i],
                                         lng = poly.points@coords[,"coords.x1"][i]))
}

species = c()
max.freq = c()
avg.freq = c()
for(i in unique(allData$speciesCode)){
  species = c(species, i)
  to.no.100 =  unlist(allData[allData$speciesCode == i,][2])
  no.100 = to.no.100[to.no.100 != 100]
  max.freq = c(max.freq, max(no.100))
  avg.freq = c(avg.freq, mean(no.100))
}
mydata = data.frame(species, max.freq, avg.freq)
View(mydata)


#write.csv(mydata, file = paste(file, ".csv", sep = ""))

