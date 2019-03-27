#download shapefile from https://data.cityofevanston.org/Information-Technology-includes-maps-geospatial-da/Trees/utcj-vfdh

# set dependencies
library(rgdal)
library(broom)
library(leaflet)
library(htmltools)
library(ggplot2)
library(dplyr)
library(sf)
library(raster)
library(spData)
library(treemap)

#read shapefile data from working directory (geo_export_e8bbf4c5-0fec-44f8-bef7-e6204a3a59c2.shp)
shape <- readOGR(dsn = ".")

#convert to data frame
shape <- fortify(as.data.frame(shape), region="id")

#remove rows from shape dataframe where species value is a vacant lot or stump
shape <- shape %>% filter(!grepl('Vacant|stump', spp))

#add column to shape dataframe for tree genus
shape$genus <- sub(" .*", "", shape$spp)

#generate genus palette 
genus.pal <-  colorFactor(c(distinctColorPalette(length(unique(shape$genus)))), domain = shape$genus)
#generate interactive leaflet map showing tree coords as circles colored by genus
#with popup labels showing species
leaflet(shape) %>%addProviderTiles(providers$CartoDB.Positron) %>%
  addCircleMarkers(~coords.x1, ~coords.x2,
                   radius = 3,
                   color = ~genus.pal(genus),
                   stroke = FALSE, fillOpacity = 0.5, label = ~htmlEscape(spp)) %>%
  addLegend(pal = genus.pal, values = shape$genus,
            title = "Tree genera")



#Filter shape data frame by species of Elm ('Ulmus')
Elm.species <- shape %>% filter(grepl('Ulmus', spp))

#create color function ramping from red to green
colfunc <- colorRampPalette(c("green", "red"))

#make list of conditions
conditions <- c("Excellent", "Very Good", "Good", "Fair", "Poor", "Critical", "Dead", "N/A")

#generate color palette using color function for categories, set "NA" to gray
pal <- colorFactor(c(colfunc(7), "gray"), domain = conditions , ordered = TRUE, levels = conditions)

#import raster data
raster_filepath <- "surface_temp_data/LC08_CU_021007_20160912_20181201_C01_V01_ST.tif"
r <- raster(raster_filepath)

#aggregate raster data to decrease file size 
r <- aggregate(r)

#generate color palette for raster data 
temp.pal <- colorNumeric(c("#0C2C84", "#41B6C4", "#FFFFCC"), values(r),
                    na.color = "transparent")

#plot only points for elm trees colored by condition with popup labels showing condition and species name
#on top of surface temp raster data with legends for each, tried to reorder Elm tree legend but it's being a turd
#zoomed in on Evanston area 
leaflet(Elm.species) %>%  setView(lng = -87.69, lat = 42.06, zoom = 12) %>%
addProviderTiles(providers$CartoDB.Positron) %>%
  addRasterImage(r, colors = temp.pal, opacity = 0.4) %>%
  addLegend(pal = temp.pal, values = values(r),
            title = "Surface temp") %>%
  addCircleMarkers(~coords.x1, ~coords.x2,
                   radius = 3,
                   color = ~pal(condition),
                   stroke = FALSE, fillOpacity = 0.5, label = ~htmlEscape(paste0(spp, '.', condition))) %>%
  addLegend(pal = pal, values = Elm.species$condition,
            title = "Elm Tree Conditions")

#create treemap

#summarize genus data from shape dataframe
treemap.data <- count(shape, genus=genus)

#Evanston treemap 
treemap(treemap.data,
        index="genus",
        vSize="n",
        type="index"
)


#regional municipallities treemap
# Create data
regional.genus=c("Maple","Ash","Honeylocust","Linden","Oak","Other")
regional.count=c(30,15,10,7,6,32)
regional.treemap.data=data.frame(regional.genus,regional.count)

treemap(regional.treemap.data,
        index="regional.genus",
        vSize="regional.count",
        type="index"
)