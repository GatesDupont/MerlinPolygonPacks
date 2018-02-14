### Merlin Polygon Pack Builder ###
### by Gates Dupont             ###
### February 10th, 2018         ###
###################################

library(rgdal)
library(sp)
library(sf)
library(maptools)
library(mapproj)
library(leaflet)

###--------------POLYGON GRID--------------------

# Importing KML file and setting projection // drawn in Google Earth)
in.poly = readOGR(ds = "AmazonRainforest.kml", layer = "AmazonRainforest") 
proj4string(in.poly) <- "+proj=longlat +datum=WGS84 +no_defs"
#mapproject(my.poly@bbox["x",], my.poly@bbox["y",], projection = "albers")

# Albers Equal Area
aea.proj = paste("+proj=aea +lat_1=", in.poly@bbox["y",][1], 
                 " +lat_2=", in.poly@bbox["y",][2], 
                 " +lat_0=", (in.poly@bbox["y",][2] + in.poly@bbox["y",][1])/2, 
                 " +lon_0=", (in.poly@bbox["x",][2] + in.poly@bbox["x",][1])/2, 
                 " +x_0=0 +y_0=0 +ellps=GRS80 +datum=NAD83 +units=m", sep = "")
my.poly = spTransform(in.poly, CRS(aea.proj))

# Creating grid of points // n = (# points)
grdpts = makegrid(my.poly, cellsize = 20000) # 20,000 m = 20 km

# Converting from df to spdf
coords = cbind(grdpts$x1, grdpts$x2)
sp = SpatialPoints(coords)
proj4string(sp) <- CRS(proj4string(my.poly)) # spdf = SpatialPointsDataFrame(coords, grdpts, proj4string = CRS(proj4string(my.poly)))

# Selecting only points in the polygon
poly.points = sp[complete.cases(over(sp,my.poly))]

# Plotting using R
plot(my.poly)
points(poly.points)

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

