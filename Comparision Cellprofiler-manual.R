

##### COMPARE NUMBER OF NON-TRUNKS CELLPROFILER WITH MANUAL #####

Test_Nontrunk <- Test_Nontrunk
names(Test_Nontrunk)[names(Test_Nontrunk) == 'ObjectSkeleton_NumberNonTrunkBranches_MorphologicalSkeleton'] <- 'Cell_Profiler'
names(Test_Nontrunk)[names(Test_Nontrunk) == 'Manual_Non_Trunk'] <- 'Manual'


longer_data_Nontrunk <- Test_Nontrunk %>%
  pivot_longer(Manual:Cell_Profiler, names_to = "Method", values_to = "Number")



ggplot(longer_data_Nontrunk, aes(x= Method, y = Number, group = ImageNumber))+
  geom_point(size=4.5, aes(colour=ImageNumber), alpha=0.6)+
  geom_line(size=1, alpha=0.5)+
  scale_color_viridis(option = "D")+
  theme(legend.position="none")+
  expand_limits(y=c(0, 50))+
  theme_light()+
  xlab("Method") + ylab("Number of Branches")
  



##### COMPARE NUMBER OF TRUNKS CELLPROFILER WITH MANUAL #####

Test_Trunk <- Test_Trunk
names(Test_Trunk)[names(Test_Trunk) == 'ObjectSkeleton_NumberTrunks_MorphologicalSkeleton'] <- 'Cell_Profiler'
names(Test_Trunk)[names(Test_Trunk) == 'Manual_Trunk'] <- 'Manual'


longer_data_Trunk <- Test_Trunk %>%
  pivot_longer(Manual:Cell_Profiler, names_to = "Method", values_to = "Number")


ggplot(longer_data_Trunk, aes(x= Method, y = Number, group = ImageNumber))+
  geom_point(size=4.5, aes(colour=ImageNumber), alpha=0.6)+
  theme(legend.position="none")+
  geom_line(size=1, alpha=0.5)+
  scale_color_viridis(option = "D")+
  theme(legend.position="none")+
  expand_limits(y=c(0, 15))+
  theme_light()+
  xlab("Method") + ylab("Number of Branches")

##### CORRPLOT FOR ALL FEATURE COMPARISION #####

Test$Total_branches_cellprofiler <- Test$ObjectSkeleton_Trunks + Test$ObjectSkeleton_NonTrunk
Test$Total_branches_manual <- Test$Manual_Trunk + Test$Manual_Non_Trunk
Test = subset(Test, select = -c(cellcount_automated,cellcount_manual) )

corr_test <- cor(Test)
corrplot(corr_test, method = "circle", type = 'lower')
