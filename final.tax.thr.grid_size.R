### Merlin Polygon Pack Builder ###
### by Gates Dupont             ###
### March 2018                  ###
###################################

########
"INPUTS"
########

##############################################################################

KML = "{{polygon-file-name}}.kml"
kml.layer = "{{polygon-layer-name}}" # Not sure? See ogrInfo(KML)
APIkey = "{{merlin-user-key}}"
checklist_threshold = 1 #[1, 99999]
grid_size = 20 # in Kilometers (km)
csvOuput = "Frequency_data_{{REGION}}"

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

# Pull frequencies from internal API
freq.API.pull = function(lat, lng, thr){
  url = paste("https://ebird.org/ws2.0/product/geo/freqlist?lat=", 
              lat, "&lng=", lng, "&key=", APIkey,
              "&thr=", thr,
              "&includePrecisionInfo=true", sep = "")
  data = fromJSON(readLines(url, warn=FALSE))
  data = data$frequencies
  return(data)
}

# Pull taxnomy data from internal API
tax.API.pull = function(species){
  species = paste(species, collapse=',')
  url = paste0("https://ebird.org/ws2.0/ref/taxonomy/ebird?fmt=json&species=", species)
  data = fromJSON(readLines(url, warn=FALSE))
  data = data.frame(data$taxonOrder, data$sciName, data$comName, data$speciesCode)
  colnames(data) = c("TaxonomicOrder", "ScientificName", "CommonName", "SpeciesCode")
  return(data)
}

###--------------POLYGON GRID--------------------

# Importing KML file and setting projection // drawn in Google Earth)
in.poly = readOGR(ds = KML, layer = kml.layer) 
proj4string(in.poly) <- "+proj=longlat +datum=WGS84 +no_defs"

# Albers Equal Area
aea.proj = paste("+proj=aea +lat_1=", in.poly@bbox["y",][1], 
                 " +lat_2=", in.poly@bbox["y",][2], 
                 " +lat_0=", (in.poly@bbox["y",][2] + in.poly@bbox["y",][1])/2, 
                 " +lon_0=", (in.poly@bbox["x",][2] + in.poly@bbox["x",][1])/2, 
                 " +x_0=0 +y_0=0 +ellps=GRS80 +datum=NAD83 +units=m", sep = "")
my.poly = spTransform(in.poly, CRS(aea.proj))

# Creating grid of points
grdpts = makegrid(my.poly, cellsize = (grid_size*1000)) #km to m

# Converting from df to spdf
coords = cbind(grdpts$x1, grdpts$x2)
sp = SpatialPoints(coords)
proj4string(sp) <- CRS(proj4string(my.poly)) # spdf = SpatialPointsDataFrame(coords, grdpts, proj4string = CRS(proj4string(my.poly)))

# Selecting only points in the polygon
poly.points = sp[complete.cases(over(sp,my.poly))]

###-----------CHECK: PLOTTING POLYGON AND POINTS - Leaflet ---------------

# Retrotransforming poly.points to something eBird can use
API.points = spTransform(poly.points, CRS(proj4string(in.poly)))

# Creating bounding box points
x = c(in.poly@bbox["x",][1],in.poly@bbox["x",][1],in.poly@bbox["x",][2],in.poly@bbox["x",][2])
y = c(in.poly@bbox["y",][1],in.poly@bbox["y",][2],in.poly@bbox["y",][1],in.poly@bbox["y",][2])

# Plotting the points
leaflet(in.poly) %>% addProviderTiles(providers$CartoDB.Positron) %>%
  addPolygons(color = "lightblue") %>%
  addCircleMarkers(lat = API.points@coords[,"coords.x2"], 
                   lng = API.points@coords[,"coords.x1"],
                   color = "green" ,radius = 0.8) %>%
  addMarkers(lng = x, lat = y)

###--------------PULLING FREQUENCY FROM GRID--------------------

allData = data.frame()
for(i in (1:length(API.points@coords[,"coords.x1"]))){
  allData = rbind(allData, freq.API.pull(lat = API.points@coords[,"coords.x2"][i],
                                         lng = API.points@coords[,"coords.x1"][i],
                                         thr = checklist_threshold))
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

# Turning off scientific notation for matrix
options(scipen=999)

# Cleaning filter-level frequencies of 100
m = as.matrix(mydata)
m[m == -Inf & is.na(m)] = 0
rawOutput0 = as.data.frame(m)

# Preparing to combine taxnomony
rawOutput = rawOutput0[order(rawOutput0$species),] 
erdTax0 = tax.API.pull(rawOutput$species)
erdTax = erdTax0[order(erdTax0$SpeciesCode),]

# Final output, ordered, with combined taxonomy
output = cbind(erdTax, rawOutput)
output$species = NULL # Dropping duplicate column originally used to check row alignment
output = output[order(output$TaxonomicOrder),]

View(output)

#write.csv(output, file = paste(csvOuput, ".csv", sep = ""))
