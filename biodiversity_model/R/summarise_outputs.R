# this script loads in the model outputs from a slurm run and produces some maps/plots for the model pipeline deliverable.

library(terra)
library(magrittr)
library(ggplot2)
library(sf)



#load species list
species_list <- read.csv("species_info/cairngorms_sp_list.csv")

#load maps and models
maps <- list.files("outputs/maps",pattern = "*.tif",full.names = T)
models <- list.files("outputs/maps",pattern = "*.RDS",full.names = T)

#get taxon ids for naming layers of 
taxon_ids <- maps %>% 
  lapply(function(x){regmatches(x, regexpr("(?<=_)[0-9]+(?=_)|(?<=_)[0-9]+$", x, perl=TRUE))}) %>% unlist()

#get taxon ids for naming layers
taxon_ids_models <- models %>% 
  lapply(function(x){regmatches(x, regexpr("(?<=_)[0-9]+(?=_)|(?<=_)[0-9]+$", x, perl=TRUE))}) %>% unlist()

# maps----------
# load as spatrasters
distributions <- maps %>% lapply(function(x){rast(x)[[1]]}) %>% rast()
names(distributions) <- taxon_ids
writeRaster(distributions,"outputs/maps/biodiversity.tif")

data_needs <- maps %>% lapply(function(x){rast(x)[[2]]}) %>% rast()
names(data_needs) <- taxon_ids
writeRaster(data_needs,"outputs/maps/dataneeds.tif")

#load boundary shapefile
boundary <- st_read("inputs/SG_CairngormsNationalPark_2010/SG_CairngormsNationalPark_2010.shp") %>% st_transform(crs=crs(distributions))

#colours for map
cl <- rev(c("#FDE725", "#B3DC2B", "#6DCC57", "#36B677", "#1F9D87", "#25818E", "#30678D", "#3D4988", "#462777", "#440154"))

#species richness
sp_richness <- sum(distributions) %>% mask(boundary)

#data needs 
data_needs_overall <- mean(data_needs,na.rm=T) %>% mask(boundary)



par(mfrow=c(1,2))
plot(sp_richness,col=viridisLite::viridis(100),main = "Species richness (calculated from 72 pilot species)")
plot(data_needs_overall,col=viridisLite::viridis(100),main = "Wildlife recording priority")
par(mfrow=c(1,1))


plot(rast(maps[[41]])$constrained%>% mask(boundary),col=viridisLite::viridis(100))

#mean species occurrence
mean_dist <- distributions %>% lapply(values) %>% lapply(function(x){mean(x,na.rm=T)})
names(mean_dist) <- names(distributions)
mean_dist <- data.frame(taxon_id = names(mean_dist),mean_dist = unlist(mean_dist))

#models ------------
model_summaries <- models %>% lapply(function(x){
  mod <- readRDS(x)
  data <- dplyr::bind_rows(mod[[1]]$performance,
                    mod[[2]]$performance,
                    mod[[3]]$performance,
                    mod[[4]]$performance)
  data$taxon_id <- regmatches(x, regexpr("(?<=_)[0-9]+(?=_)|(?<=_)[0-9]+$", x, perl=TRUE))
  data
}) %>%
  dplyr::bind_rows()

model_summaries <- model_summaries %>%
  dplyr::mutate(taxon_id = as.numeric(taxon_id)) %>%
  dplyr::left_join(species_list,by = c("taxon_id"="speciesKey"))

plot_data <- model_summaries %>% dplyr::filter(threshold == "equal_sens_spec")

plot_data <- plot_data %>% dplyr::mutate(model=factor(model,levels = c("glm","gau","svm","meanw"))) 


plot_data %>%
  ggplot(aes(x =sci_name,y = AUC_mean,colour = model))+
  geom_point()+
  theme_minimal()+ theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1,size=7),legend.position = "top")+
  #scale_colour_manual(values = c("grey", "#3D4988"))+
  xlab("Species (scientific name)")+
  ylab("AUC")

plot_data %>%
  ggplot(aes(x =model,y = AUC_mean,fill = model))+
  geom_boxplot()+
  theme_minimal()+ theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1),legend.position = "none")+
  #scale_colour_manual(values = c("grey", "#3D4988"))+
  xlab("Model type")+
  ylab("AUC")










