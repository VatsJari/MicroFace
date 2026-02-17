# ============================================
# FIG1 - Radial Bins Visualization (CUSTOMIZABLE)
# ============================================

Fig1 <- list()

# Calculate radial distance and bins
Fig1$data <- import$df_all

# Calculate radial distance from injury site
Fig1$data$radial_dist <- sqrt(
  (Fig1$data$Center_X_soma - Fig1$data$Injury_x)^2 + 
    (Fig1$data$Center_Y_soma - Fig1$data$Injury_y)^2
)

# Create 25 bins based on radial distance
Fig1$data$bin_number <- ntile(Fig1$data$radial_dist, 25)
Fig1$data$bin_range <- Fig1$data$bin_number * 139

# Create new bin numbering (1-16 as individual bins, 17+ combined)
Fig1$data$Bin_Number_New <- Fig1$data$bin_number 
Fig1$data$Bin_Number_New[Fig1$data$bin_number > 16] <- 17 
Fig1$data$bin_range_new <- Fig1$data$Bin_Number_New * 139

# ============================================
# FUNCTION TO PLOT SPECIFIC IMAGES
# ============================================

Fig1$plot_images <- function(image_numbers = NULL, 
                             time_weeks = NULL, 
                             ncol = 3,
                             show_circles = TRUE,
                             point_size = 0.5,
                             alpha = 0.7) {
  
  # Filter data based on input
  plot_data <- Fig1$data
  
  if (!is.null(image_numbers)) {
    plot_data <- plot_data[plot_data$ImageNumber_cell %in% image_numbers, ]
    cat("Filtering for image numbers:", paste(image_numbers, collapse = ", "), "\n")
  }
  
  if (!is.null(time_weeks)) {
    plot_data <- plot_data[plot_data$Time_weeks %in% time_weeks, ]
    cat("Filtering for time weeks:", paste(time_weeks, collapse = ", "), "\n")
  }
  
  # Get unique images to plot
  images_to_plot <- unique(plot_data$ImageNumber_cell)
  cat("Plotting", length(images_to_plot), "images\n")
  
  if (length(images_to_plot) == 0) {
    stop("No images found with specified criteria")
  }
  
  # Calculate injury coordinates per image
  injury_by_image <- plot_data %>%
    group_by(ImageNumber_cell) %>%
    summarise(
      injury_x = unique(Injury_x[!is.na(Injury_x)])[1],
      injury_y = unique(Injury_y[!is.na(Injury_y)])[1],
      Time_weeks = unique(Time_weeks[!is.na(Time_weeks)])[1],
      .groups = "drop"
    )
  
  # Create circle data if requested
  if (show_circles) {
    circle_data <- data.frame()
    
    for(img in images_to_plot) {
      img_data <- plot_data[plot_data$ImageNumber_cell == img, ]
      img_injury <- injury_by_image[injury_by_image$ImageNumber_cell == img, ]
      
      if(nrow(img_injury) > 0 && !is.na(img_injury$injury_x)) {
        
        # Calculate bin radii for this image
        img_bin_radii <- img_data %>%
          group_by(Bin_Number_New) %>%
          summarise(max_radius = max(radial_dist, na.rm = TRUE), .groups = "drop")
        
        for(i in 1:nrow(img_bin_radii)) {
          radius <- img_bin_radii$max_radius[i]
          bin_num <- img_bin_radii$Bin_Number_New[i]
          
          theta <- seq(0, 2*pi, length.out = 50)
          circle_x <- img_injury$injury_x + radius * cos(theta)
          circle_y <- img_injury$injury_y + radius * sin(theta)
          
          circle_data <- rbind(circle_data,
                               data.frame(x = circle_x,
                                          y = circle_y,
                                          Bin = bin_num,
                                          ImageNumber_cell = img))
        }
      }
    }
  }
  
  # Create the plot
  p <- ggplot() +
    # Cell points
    geom_point(data = plot_data, 
               aes(x = Center_X_soma, y = Center_Y_soma, color = as.factor(Bin_Number_New)),
               size = point_size, alpha = alpha) +
    # Add circles if requested
    (if (show_circles) {
      geom_path(data = circle_data, 
                aes(x = x, y = y, group = interaction(Bin, ImageNumber_cell), 
                    color = as.factor(Bin)),
                linetype = "dashed", linewidth = 0.3)
    }) +
    # Injury sites
    geom_point(data = injury_by_image,
               aes(x = injury_x, y = injury_y),
               color = "red", size = 3, shape = 8) +
    scale_color_viridis_d(name = "Bin") +
    facet_wrap(~ImageNumber_cell, ncol = ncol, scales = "free") +
    theme_classic() +
    labs(title = "Cell Positions by Image with Radial Bins",
         x = "Center X (soma)", y = "Center Y (soma)") +
    theme(
      plot.title = element_text(size = 16, hjust = 0.5, face = "bold"),
      strip.text = element_text(size = 10, face = "bold"),
      axis.title = element_text(size = 10, face = "bold"),
      axis.text = element_text(size = 6),
      legend.position = "bottom",
      legend.key.size = unit(0.5, "lines")
    )
  
  return(p)
}

# ============================================
# FUNCTION TO PLOT SINGLE IMAGE DETAIL
# ============================================

Fig1$plot_single_image <- function(image_number, 
                                   show_circles = TRUE,
                                   point_size = 1,
                                   alpha = 0.8) {
  
  # Filter for single image
  plot_data <- Fig1$data[Fig1$data$ImageNumber_cell == image_number, ]
  
  if (nrow(plot_data) == 0) {
    stop(paste("Image", image_number, "not found"))
  }
  
  # Get injury coordinates
  injury_x <- unique(plot_data$Injury_x[!is.na(plot_data$Injury_x)])[1]
  injury_y <- unique(plot_data$Injury_y[!is.na(plot_data$Injury_y)])[1]
  time_week <- unique(plot_data$Time_weeks[!is.na(plot_data$Time_weeks)])[1]
  
  # Create circle data if requested
  if (show_circles) {
    bin_radii <- plot_data %>%
      group_by(Bin_Number_New) %>%
      summarise(max_radius = max(radial_dist, na.rm = TRUE), .groups = "drop")
    
    circle_data <- data.frame()
    for(i in 1:nrow(bin_radii)) {
      radius <- bin_radii$max_radius[i]
      bin_num <- bin_radii$Bin_Number_New[i]
      
      theta <- seq(0, 2*pi, length.out = 100)
      circle_x <- injury_x + radius * cos(theta)
      circle_y <- injury_y + radius * sin(theta)
      
      circle_data <- rbind(circle_data,
                           data.frame(x = circle_x,
                                      y = circle_y,
                                      Bin = bin_num))
    }
  }
  
  # Create plot
  p <- ggplot() +
    geom_point(data = plot_data, 
               aes(x = Center_X_soma, y = Center_Y_soma, color = as.factor(Bin_Number_New)),
               size = point_size, alpha = alpha) +
    (if (show_circles) {
      geom_path(data = circle_data, 
                aes(x = x, y = y, group = Bin, color = as.factor(Bin)),
                linetype = "dashed", linewidth = 0.5)
    }) +
    geom_point(aes(x = injury_x, y = injury_y), 
               color = "red", size = 4, shape = 8) +
    scale_color_viridis_d(name = "Bin Number") +
    theme_classic() +
    labs(title = paste("Image", image_number, "- Time Week:", time_week),
         subtitle = paste("Total cells:", nrow(plot_data), 
                          "| Injury at (", round(injury_x, 0), ",", round(injury_y, 0), ")"),
         x = "Center X (soma)", y = "Center Y (soma)") +
    theme(
      plot.title = element_text(size = 14, hjust = 0.5, face = "bold"),
      plot.subtitle = element_text(size = 12, hjust = 0.5),
      axis.title = element_text(size = 12, face = "bold"),
      legend.position = "right"
    )
  
  return(p)
}

# ============================================
# FUNCTION TO EXPLORE AVAILABLE IMAGES
# ============================================

Fig1$list_available_images <- function() {
  
  image_summary <- Fig1$data %>%
    group_by(ImageNumber_cell, Time_weeks, Electrode_Thickness) %>%
    summarise(
      n_cells = n(),
      avg_radial_dist = mean(radial_dist, na.rm = TRUE),
      injury_x = unique(Injury_x[!is.na(Injury_x)])[1],
      injury_y = unique(Injury_y[!is.na(Injury_y)])[1],
      .groups = "drop"
    ) %>%
    arrange(Time_weeks, ImageNumber_cell)
  
  return(image_summary)
}

# ============================================
# FUNCTION TO PLOT MULTIPLE IMAGES BY TIME
# ============================================

Fig1$plot_by_time <- function(time_week, 
                              n_images = 6, 
                              random = FALSE,
                              show_circles = TRUE) {
  
  # Get images for this time point
  time_images <- Fig1$data %>%
    filter(Time_weeks == time_week) %>%
    group_by(ImageNumber_cell) %>%
    summarise(n_cells = n(), .groups = "drop") %>%
    arrange(desc(n_cells))
  
  if (random) {
    selected_images <- sample(time_images$ImageNumber_cell, 
                              min(n_images, nrow(time_images)))
  } else {
    selected_images <- time_images$ImageNumber_cell[1:min(n_images, nrow(time_images))]
  }
  
  cat("Plotting", length(selected_images), "images from Time Week", time_week, "\n")
  
  Fig1$plot_images(image_numbers = selected_images, 
                   show_circles = show_circles,
                   ncol = 3)
}

# ============================================
# EXAMPLES OF HOW TO USE
# ============================================

# First, see what images are available
cat("\n=== AVAILABLE IMAGES ===\n")
Fig1$image_summary <- Fig1$list_available_images()
print(head(Fig1$image_summary, 20))

# Example 1: Plot specific image numbers
# Fig1$plot1 <- Fig1$plot_single_image(image_number = 1)  # Plot image 1
# print(Fig1$plot1)

# Example 2: Plot multiple specific images
# Fig1$plot2 <- Fig1$plot_images(image_numbers = c(1, 5, 10), ncol = 2)
# print(Fig1$plot2)

# Example 3: Plot images from specific time point
# Fig1$plot3 <- Fig1$plot_by_time(time_week = 2, n_images = 6)
# print(Fig1$plot3)

# Example 4: Plot images without circles (cleaner)
# Fig1$plot4 <- Fig1$plot_images(image_numbers = c(1, 2, 3), show_circles = FALSE)
# print(Fig1$plot4)

# Example 5: Plot single image with larger points
# Fig1$plot5 <- Fig1$plot_single_image(image_number = 1, point_size = 2, alpha = 0.9)
# print(Fig1$plot5)

# ============================================
# INTERACTIVE SELECTION (if you want to choose)
# ============================================

Fig1$interactive_select <- function() {
  cat("\nAvailable Time Weeks:", unique(Fig1$data$Time_weeks), "\n")
  time_input <- readline(prompt = "Enter Time Week: ")
  time_input <- as.numeric(time_input)
  
  if (!is.na(time_input)) {
    images_in_time <- unique(Fig1$data$ImageNumber_cell[Fig1$data$Time_weeks == time_input])
    cat("\nImages in Time Week", time_input, ":", paste(images_in_time, collapse = ", "), "\n")
    
    image_input <- readline(prompt = "Enter image numbers (comma-separated, or 'all'): ")
    
    if (tolower(image_input) == "all") {
      selected_images <- images_in_time
    } else {
      selected_images <- as.numeric(unlist(strsplit(image_input, ",")))
    }
    
    Fig1$plot_images(image_numbers = selected_images)
  }
}


# 1. First, see what images are available
Fig1$list_available_images()

# 2. Plot a single image in detail
Fig1$plot_single_image(image_number = 5)

# 3. Plot multiple specific images
Fig1$plot_images(image_numbers = c(1, 5, 10, 15), ncol = 2)

# 4. Plot images from a specific time point
Fig1$plot_by_time(time_week = "00WPI", n_images = 4)+
  facet_grid(ImageNumber_cell~Electrode_Thickness)

# 5. Plot without circles (cleaner)
Fig1$plot_images(image_numbers = c(1, 2, 3), show_circles = FALSE)

# 6. Customize point size and transparency
Fig1$plot_single_image(image_number = 1, point_size = 2, alpha = 0.9)

# 7. Interactive mode - let R ask you which images to plot
Fig1$interactive_select()





cat("\n=== FIG1 READY ===\n")
cat("\nAvailable functions:\n")
cat("  Fig1$list_available_images() - See all images with metadata\n")
cat("  Fig1$plot_single_image(image_number) - Plot one image in detail\n")
cat("  Fig1$plot_images(image_numbers) - Plot multiple specific images\n")
cat("  Fig1$plot_by_time(time_week) - Plot top images from a time point\n")
cat("  Fig1$interactive_select() - Interactive selection\n")