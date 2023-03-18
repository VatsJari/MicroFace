

##### COMPARE NUMBER OF TRUNKS CELLPROFILER WITH MANUAL #####



# Create a list object to store multiple plots
validation <- list()


# load the datasheet which contains the measured and counted values of the branches
validation$data <- read_excel("/Volumes/JARI-NES/Brain Injury project/Test/Test.xlsx")



# plot the graph of comparison of two methods

validation$trunk <- ggplot(validation$data, aes(x = ObjectSkeleton_NumberTrunks_MorphologicalSkeleton, y = Manual_Trunk)) +
  geom_point(size = 3, color = 'blue') +
  geom_jitter(size = 3, width = 0.5, colour = 'blue')+
  geom_smooth(method = "lm", se = T, color = 'green') +        
  ggpubr :: stat_cor(method = "pearson", color = 'black')+      # Calculate and add the R-squared value and significance 
  labs(x = "Automated Analysis", y = "Manual Analysis") +
  ggtitle("Trunk Branches")+
  theme_bw()+
  theme(
    
    plot.title = element_text(size=20, hjust = 0.5, face="bold"),
    axis.title.x = element_text(size=18, face="bold"),
    axis.title.y = element_text(size=18, face="bold"),
    axis.text.x = element_text(size = 16, face="bold"),
    axis.text.y  = element_text(size = 16, face="bold")
  )


# Print the plot
print(validation$trunk)





##### COMPARE NUMBER OF NON-TRUNKS CELLPROFILER WITH MANUAL #####

# plot the graph of comparison of two methods

validation$non_trunk <- ggplot(validation$data, aes(x = ObjectSkeleton_NumberNonTrunkBranches_MorphologicalSkeleton, y = Manual_Non_Trunk)) +
  geom_point(size = 3, color = 'blue') +
  geom_jitter(size = 3, width = 5, colour = 'blue')+
  geom_smooth(method = "lm", se = T, color = 'green') +
  ggpubr :: stat_cor(method = "pearson", color = 'black')+      # Calculate and add the R-squared value and significance 
  labs(x = "Automated Analysis", y = "Manual Analysis") +
  ggtitle("Non-Trunk Branches")+
  theme_bw()+
  theme(
    
    plot.title = element_text(size=20, hjust = 0.5, face="bold"),
    axis.title.x = element_text(size=18, face="bold"),
    axis.title.y = element_text(size=18, face="bold"),
    axis.text.x = element_text(size = 16, face="bold"),
    axis.text.y  = element_text(size = 16, face="bold")
  )




# Print the plot
print(validation$non_trunk)


##### COMPARE AREA CELLPROFILER WITH MANUAL #####

# plot the graph of comparison of two methods

validation$area <- ggplot(validation$data, aes(x = AreaShape_Area, y = Manual_Area)) +
  geom_point(size = 3, color = 'blue') +
  geom_jitter(size = 3, width = 5, colour = 'blue')+
  geom_smooth(method = "lm", se = T, color = 'green') +
  ggpubr :: stat_cor(method = "pearson", color = 'black')+      # Calculate and add the R-squared value and significance 
  labs(x = "Automated Analysis", y = "Manual Analysis") +
  ggtitle("Area")+
  theme_bw()+
  theme(
    
    plot.title = element_text(size=20, hjust = 0.5, face="bold"),
    axis.title.x = element_text(size=18, face="bold"),
    axis.title.y = element_text(size=18, face="bold"),
    axis.text.x = element_text(size = 16, face="bold"),
    axis.text.y  = element_text(size = 16, face="bold")
  )




# Print the plot
print(validation$area)







##### CORRPLOT FOR ALL FEATURE COMPARISION #####

Test$Total_branches_cellprofiler <- Test$ObjectSkeleton_Trunks + Test$ObjectSkeleton_NonTrunk
Test$Total_branches_manual <- Test$Manual_Trunk + Test$Manual_Non_Trunk
Test = subset(Test, select = -c(cellcount_automated,cellcount_manual) )

corr_test <- cor(Test)
corrplot(corr_test, method = "circle", type = 'lower')
