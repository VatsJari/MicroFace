# ============================================================================
# FIGURE 1: Radial Bins Visualization (Facet by Time and Thickness)
# FIGURE S4 : Radial Bins Visualization (Facet by Time and Thickness)
# ============================================================================
# This script creates plots of cell positions with radial bins from the injury
# site, faceted by time point and electrode thickness. All outputs are stored
# in the 'Fig1' list.
# ============================================================================

# Initialize list
Fig1 <- list()

# ============================================================================
# 1. Data Preparation: Calculate Radial Distance and Bins
# ============================================================================

Fig1$data <- ClusterAnalysis$final_df_full

#============================================================================
# 2. Helper Function: Short Filename for Display
# ============================================================================

Fig1$short_filename <- function(filenames, max_length = 30) {
  # Extract just the base filename without path
  short_names <- basename(as.character(filenames))
  # Truncate if too long
  short_names <- ifelse(nchar(short_names) > max_length,
                        paste0(substr(short_names, 1, max_length), "..."),
                        short_names)
  return(short_names)
}

# ============================================================================
# 3. Main Plotting Function: Facet by Time_weeks and Electrode_Thickness
# ============================================================================

Fig1$plot_by_time_thickness <- function(bins_to_show = 1:5,
                                        n_images_per_time = 1,
                                        time_weeks = NULL,
                                        electrode_thickness = NULL,
                                        random = FALSE,
                                        point_size = 0.1,
                                        alpha = 0.7,
                                        show_circles = TRUE) {
  
  # Start with all data
  filtered_data <- Fig1$data
  
  # Filter by electrode thickness if specified
  if (!is.null(electrode_thickness)) {
    filtered_data <- filtered_data %>%
      filter(Electrode_Thickness %in% as.character(electrode_thickness))
    cat("Filtering for electrode thickness:", paste(electrode_thickness, collapse = ", "), "\n")
  }
  
  # Determine which time weeks to use
  if (is.null(time_weeks)) {
    unique_times <- unique(filtered_data$Time_weeks)
  } else {
    unique_times <- as.character(time_weeks)
  }
  
  cat("Time weeks found:", paste(unique_times, collapse = ", "), "\n")
  
  # Get all unique images (with thickness and time)
  all_images <- filtered_data %>%
    distinct(FileName_Original_Iba1_cell, ImageNumber_cell, Time_weeks, Electrode_Thickness) %>%
    arrange(Time_weeks, Electrode_Thickness, FileName_Original_Iba1_cell)
  
  cat("\nTotal unique images found:", nrow(all_images), "\n")
  
  # Show distribution by time week and thickness
  cat("\nImage distribution:\n")
  dist_summary <- all_images %>%
    group_by(Time_weeks, Electrode_Thickness) %>%
    summarise(n = n(), .groups = "drop") %>%
    arrange(Time_weeks, Electrode_Thickness)
  print(dist_summary)
  
  # --------------------------------------------------------------------------
  # Select up to n_images_per_time for each combination of time_weeks and electrode_thickness
  # --------------------------------------------------------------------------
  selected_images <- data.frame()
  
  # Get all unique thicknesses present in the filtered data
  thicknesses_present <- unique(all_images$Electrode_Thickness)
  
  for (tw in unique_times) {
    for (th in thicknesses_present) {
      # Get images for this time week and thickness
      combo_images <- all_images %>%
        filter(Time_weeks == tw, Electrode_Thickness == th)
      
      if (nrow(combo_images) > 0) {
        n_to_select <- min(n_images_per_time, nrow(combo_images))
        
        if (random && n_to_select < nrow(combo_images)) {
          selected_idx <- sample(1:nrow(combo_images), n_to_select)
          selected <- combo_images[selected_idx, ]
        } else {
          selected <- combo_images[1:n_to_select, ]
        }
        
        selected_images <- rbind(selected_images, selected)
        
        cat("\n  Time week", tw, "| Thickness", th, ": selected", n_to_select, "image(s):\n")
        for(i in 1:nrow(selected)) {
          short_name <- Fig1$short_filename(selected$FileName_Original_Iba1_cell[i], 25)
          cat("    -", short_name, 
              "(Image", selected$ImageNumber_cell[i], ")\n")
        }
      } else {
        cat("\n  Time week", tw, "| Thickness", th, ": NO IMAGES FOUND\n")
      }
    }
  }
  
  cat("\nTotal selected images:", nrow(selected_images), "\n")
  
  # --------------------------------------------------------------------------
  # Filter data for selected images and specified bins
  # --------------------------------------------------------------------------
  plot_data <- Fig1$data %>%
    inner_join(selected_images[, c("FileName_Original_Iba1_cell", "Time_weeks")], 
               by = c("FileName_Original_Iba1_cell", "Time_weeks")) %>%
    filter(Bin_Number_New %in% bins_to_show)
  
  # Create a clean filename column for metadata
  plot_data$Display_Name <- Fig1$short_filename(plot_data$FileName_Original_Iba1_cell, 20)
  
  # Make Time_weeks and Electrode_Thickness factors with all levels we want to appear
  plot_data$Time_weeks <- factor(plot_data$Time_weeks, levels = unique_times)
  plot_data$Electrode_Thickness <- factor(plot_data$Electrode_Thickness, 
                                          levels = thicknesses_present)
  
  # Get injury coordinates for each image
  injury_data <- plot_data %>%
    group_by(FileName_Original_Iba1_cell, Display_Name, ImageNumber_cell, 
             Time_weeks, Electrode_Thickness) %>%
    summarise(
      injury_x = first(na.omit(Injury_x)),
      injury_y = first(na.omit(Injury_y)),
      .groups = "drop"
    )
  
  injury_data$Time_weeks <- factor(injury_data$Time_weeks, levels = unique_times)
  injury_data$Electrode_Thickness <- factor(injury_data$Electrode_Thickness, 
                                            levels = thicknesses_present)
  
  # --------------------------------------------------------------------------
  # Create circle data (if requested)
  # --------------------------------------------------------------------------
  circle_data <- data.frame()
  
  if (show_circles) {
    for(i in 1:nrow(injury_data)) {
      filename <- injury_data$FileName_Original_Iba1_cell[i]
      display_name <- injury_data$Display_Name[i]
      tw <- injury_data$Time_weeks[i]
      
      img_data <- plot_data %>%
        filter(FileName_Original_Iba1_cell == filename, Time_weeks == tw)
      
      if(!is.na(injury_data$injury_x[i]) && !is.na(injury_data$injury_y[i])) {
        
        # Get max radius for each bin
        bin_radii <- img_data %>%
          group_by(Bin_Number_New) %>%
          summarise(radius = max(radial_dist, na.rm = TRUE), .groups = "drop")
        
        # Create circle for each bin
        for(j in 1:nrow(bin_radii)) {
          theta <- seq(0, 2*pi, length.out = 50)
          circle_data <- rbind(circle_data,
                               data.frame(
                                 x = injury_data$injury_x[i] + bin_radii$radius[j] * cos(theta),
                                 y = injury_data$injury_y[i] + bin_radii$radius[j] * sin(theta),
                                 Bin = bin_radii$Bin_Number_New[j],
                                 FileName = filename,
                                 Display_Name = display_name,
                                 ImageNumber = injury_data$ImageNumber_cell[i],
                                 Time_weeks = tw,
                                 Electrode_Thickness = injury_data$Electrode_Thickness[i]
                               ))
        }
      }
    }
    
    if (nrow(circle_data) > 0) {
      circle_data$Time_weeks <- factor(circle_data$Time_weeks, levels = unique_times)
      circle_data$Electrode_Thickness <- factor(circle_data$Electrode_Thickness, 
                                                levels = thicknesses_present)
    }
  }
  
  # --------------------------------------------------------------------------
  # Build the plot with facet_grid: Electrode_Thickness (rows) ~ Time_weeks (columns)
  # --------------------------------------------------------------------------
  p <- ggplot() +
    # Colored points by bin
    geom_point(data = plot_data, 
               aes(x = Center_X_soma, y = Center_Y_soma, color = as.factor(Bin_Number_New)),
               size = point_size, alpha = alpha) +
    # Black circles (if requested)
    {if(show_circles && nrow(circle_data) > 0) {
      geom_path(data = circle_data, 
                aes(x = x, y = y, group = interaction(Bin, FileName)),
                color = "black", linetype = "dashed", linewidth = 0.1)
    }} +
    # Injury sites
    geom_point(data = injury_data,
               aes(x = injury_x, y = injury_y),
               color = "red", size = 3, shape = 8) +
    # Color scale for bins
    scale_color_viridis_d(name = "Bin Number", 
                          limits = factor(bins_to_show),
                          guide = guide_legend(nrow = 2)) +
    # Facet grid: Electrode_Thickness (rows) vs Time_weeks (columns)
    facet_grid(Electrode_Thickness ~ Time_weeks) +
    theme_classic() +
    coord_fixed() +
    labs(title = paste(n_images_per_time, "Image(s) per Time × Thickness Combination"),
         subtitle = paste("Bins:", min(bins_to_show), "to", max(bins_to_show)),
         x = "Center X (soma)", y = "Center Y (soma)") +
    theme(
      plot.title = element_text(size = 16, hjust = 0.5),
      plot.subtitle = element_text(size = 11, hjust = 0.5),
      strip.text = element_text(size = 8),
      axis.title = element_text(size = 10),
      axis.text = element_text(size = 6),
      legend.position = "bottom",
      legend.key.size = unit(0.3, "lines"),
      panel.spacing = unit(0.5, "lines")
    )
  
  print(p)
  
  # Return the selected images as metadata (invisible)
  invisible(list(plot = p, selected = selected_images))
}

# ============================================================================
# 4. Example: Generate the main figure used in the analysis
# ============================================================================

cat("\n=== GENERATING MAIN FIGURE: Radial Bins by Time and Thickness ===\n")

Fig1$plot_by_time_thickness(
  bins_to_show = 1:16,
  n_images_per_time = 2,
  time_weeks = c("00WPI", "01WPI", "02WPI", "08WPI", "18WPI"),
  electrode_thickness = c("6", "11", "16", "50"),
  point_size = 0.001,
  alpha = 1
)

# ============================================================================
# End of Figure 1 script
# ============================================================================