#packages
install.packages("suncalc")
install.packages("sp")
install.packages("tidyverse")
install.packages("patchwork")

#packages laden
library(suncalc)
library(sp)
library(tidyverse)
library(patchwork)

#working directory setzen
getwd()
setwd("change the working directory here to the same folder as your table
      containing the objekts which cast shadows")

# Sonnenstand und Zeit eingeben ---- 
#### Sonnenzeit und Stand ermitteln für die gewünschten Zeiten. Das Format muss
#### aussehen wie unten beschrieben!

times <- seq(
  as.POSIXct("2025-05-10 04:00", tz = "Europe/Berlin"),
  as.POSIXct("2025-05-10 22:00", tz = "Europe/Berlin"),
  by = "30 min"
)

#### Hier die den gewünschten Lengthn und Widthngrad angeben
sun <- getSunlightPosition(
  date = times,
  lat = 53.235,
  lon = 8.4571
)
# sonnenHeight und winkel in Grad umwandeln 
sun$altitude_deg <- sun$altitude * 180 / pi
sun$azimuth_deg <- sun$azimuth * 180 / pi

sun_clean <- sun %>%
  select(
    date,
    altitude,
    azimuth,
    altitude_deg,
    azimuth_deg
  )

sun_clean <- sun_clean %>%
  filter(altitude_deg > 0)


#### Tabelle einlesen----
objekte <- read.csv("example_data.csv",
                    fileEncoding = "latin1",
                    check.names = FALSE) %>%
  mutate(
    Length = as.numeric(Length),
    Width = as.numeric(Width),
    Height = as.numeric(Height),
    Radius = as.numeric(Radius),
    X = as.numeric(X),
    Y = as.numeric(Y)
  )

#### Plot mit den Objekten auf dem Koordinatensystem erstellen----
# Leerer Plot
p <- ggplot() +
  coord_fixed(xlim = c(-5, 30), ylim = c(-5, 40)) +
  theme_minimal()

# Rechtecke zeichnen
rects <- objekte %>%
  filter(Form == "Rectangle")

if(nrow(rects) > 0){
  
  p <- p +
    geom_rect(
      data = rects,
      aes(
        xmin = X - Length/2,
        xmax = X + Length/2,
        ymin = Y - Width/2,
        ymax = Y + Width/2,
        fill = Object
      ),
      color = "black",
      alpha = 0.5
    ) + 
    scale_fill_manual(
      values = c(
        "Property" = "#F6DADA",   # very light pink
        "House" = "#D95F02",      # warm orange-brown
        "Fence" = "#7570B3",      # muted violet
        "Shed_1" = "#1B9E77",     # teal-green
        "Shed_2" = "#4C78A8",     # muted blue
        "Terrace" = "#8C564B"     # earthy brown contrast to pink
      )
    )
  
}

# Kreise zeichnen (Eigentlich 200 Ecke aber auf dem Plot sehen sie aus wie Kreise)
# Brechnung und schleife für einen Dataframe mit den Daten udn dann das einzeichnen
circles <- objekte %>%
  filter(Form == "Circle")

if(nrow(circles) > 0){
  
  for(i in 1:nrow(circles)){
    
    theta <- seq(0, 2*pi, length.out = 200)
    
    circle_df <- data.frame(
      x = circles$X[i] + circles$Radius[i] * cos(theta),
      y = circles$Y[i] + circles$Radius[i] * sin(theta)
    )
    
    p <- p +
      geom_polygon(
        data = circle_df,
        aes(x, y),
        fill = "darkgreen",
        color = "black",
        alpha = 0.5
      )
  }
}

# Labels
p <- p +
  geom_text(
    data = objekte,
    aes(X, Y, label = Object),
    size = 3
  )

# Plot mit Grundstück und den Objekten
p <- p +
  geom_text(
    data = objekte,
    aes(X, Y, label = Object),
    size = 3
  ) +
  
  coord_fixed(
    xlim = c(-5, 30),
    ylim = c(-5, 40),
    expand = FALSE
  ) +
  
  labs(
    title = "Property",
    x = "Width [m]",
    y = "Length [m]",
    fill = "Object"
  ) +
  
  theme_minimal() +
  
  theme(
    panel.grid = element_blank(),
    axis.line = element_line(color = "black"),
    axis.ticks = element_line(color = "black"),
    plot.title = element_text(
      hjust = 0.5,
      face = "bold",
      size = 16
    ),
    axis.title = element_text(size = 13),
    axis.text = element_text(size = 11),
    legend.position = "right"
  )
print(p) 


#### jetzt ein Gitter erstellen, um Sonnenpositionen zu ermitteln----

grid_size <- 1  # 1 Meter Auflösung

grid <- expand.grid(
  x = seq(-5, 30, by = grid_size),
  y = seq(-5, 40, by = grid_size)
)

grid$sun_minutes <- 0
grid$shadow_minutes <- 0

p +
  geom_point(
    data = grid,
    aes(x = x, y = y),
    size = 0.5,
    alpha = 0.5
  )

## code  für schatten Grundstück ----
#alle Schattenfunktion
#erst für Rectangels
make_rect_shadow <- function(obj, dx, dy) {
  
  x <- obj$X
  y <- obj$Y
  l <- obj$Length
  b <- obj$Width
  
  p1 <- c(x - l/2, y - b/2)
  p2 <- c(x + l/2, y - b/2)
  p3 <- c(x + l/2, y + b/2)
  p4 <- c(x - l/2, y + b/2)
  
  original <- rbind(p1, p2, p3, p4)
  shifted  <- original + matrix(c(dx, dy), nrow = 4, ncol = 2, byrow = TRUE)
  
  shadow <- rbind(
    original,
    shifted[4, ],
    shifted[3, ],
    shifted[2, ],
    shifted[1, ],
    original[1, ]
  )
  
  data.frame(x = shadow[, 1], y = shadow[, 2])
}

make_circle_shadow <- function(obj, dx, dy, n = 100) {
  
  theta <- seq(0, 2*pi, length.out = n)
  
  circle1 <- data.frame(
    x = obj$X + obj$Radius * cos(theta),
    y = obj$Y + obj$Radius * sin(theta)
  )
  
  circle2 <- data.frame(
    x = obj$X + dx + obj$Radius * cos(theta),
    y = obj$Y + dy + obj$Radius * sin(theta)
  )
  
  pts <- rbind(circle1, circle2)
  
  hull_id <- chull(pts$x, pts$y)
  hull <- pts[c(hull_id, hull_id[1]), ]
  
  hull
}
make_shadow <- function(obj, sun) {
  
  shadow_length <- obj$Height / tan(sun$altitude)
  shadow_angle <- sun$azimuth + pi
  
  dx <- shadow_length * sin(shadow_angle)
  dy <- shadow_length * cos(shadow_angle)
  
  if(obj$Form == "Rectangle") {
    return(make_rect_shadow(obj, dx, dy))
  }
  
  if(obj$Form == "Circle") {
    return(make_circle_shadow(obj, dx, dy))
  }
}


all_shadows <- data.frame()
shadow_objects <- objekte %>%
  filter(Height > 0)
  
for(j in 1:nrow(shadow_objects)) {
  
  obj_one <- shadow_objects[j, ]
  
  shadow_df <- make_shadow(obj_one, sun)
  
  shadow_df$Objekt <- obj_one$Objekt
  
  all_shadows <- rbind(all_shadows, shadow_df)
}
#heatmap zeichnen für alle Zeitpunkte 

time_step <- as.numeric(
  difftime(sun_clean$date[2], sun_clean$date[1], units = "mins")
)

for(i in 1:nrow(sun_clean)) {
  
  sun_one <- sun_clean[i, ]
  
  # Start: noch kein Rasterpunkt ist im Schatten
  in_shadow_total <- rep(FALSE, nrow(grid))
  
  for(j in 1:nrow(shadow_objects)) {
    
    obj_one <- shadow_objects[j, ]
    
    shadow_df <- make_shadow(obj_one, sun_one)
    
    in_shadow <- sp::point.in.polygon(
      point.x = grid$x,
      point.y = grid$y,
      pol.x = shadow_df$x,
      pol.y = shadow_df$y
    ) > 0
    
    # Wenn ein Punkt in irgendeinem Schatten liegt:
    in_shadow_total <- in_shadow_total | in_shadow
  }
  
  grid$shadow_minutes[in_shadow_total] <- grid$shadow_minutes[in_shadow_total] + time_step
  grid$sun_minutes[!in_shadow_total] <- grid$sun_minutes[!in_shadow_total] + time_step
}

grid$sun_hours <- grid$sun_minutes / 60
grid$shadow_hours <- grid$shadow_minutes / 60

p_heat <- ggplot(grid, aes(x = x, y = y, fill = sun_hours)) +
  
  geom_tile() +
  
  scale_fill_gradientn(
    colors = c("darkblue", "skyblue", "orange", "yellow")
  ) +
  
  coord_fixed(
    xlim = c(0, 25),
    ylim = c(0, 35),
    expand = FALSE
  ) +
  
  labs(
    title = "Accumulated sunlight hours",
    x = "Length [m]",
    y = "Width [m]",
    fill = "Sunlight\nhours"
  ) +
  
  theme_minimal() +
  
  theme(
    panel.grid = element_blank(),
    axis.line = element_line(color = "black"),
    axis.ticks = element_line(color = "black"),
    plot.title = element_text(
      hjust = 0.5,
      face = "bold",
      size = 24
    ),
    axis.title = element_text(size = 18),
    axis.text = element_text(size = 14),
    axis.title.y = element_blank(),
    axis.text.y = element_blank(),
    axis.ticks.y =  element_blank()
  )


p_obj <- p

p_obj + p_heat


#this function only works properly if latatide longitude and the time frame is given 
# using the parameters the begining of this script
plot_shadows_at_time <- function(wishtime, object_df) {
  
  # 1. Clean object table and remove objects without height
  shadow_objects <- object_df %>%
    filter(!is.na(Height), Height > 0)
  
  # 2. Select wished time
  sun_one <- sun_clean %>%
    filter(format(date, "%H:%M") == wishtime)
  
  if(nrow(sun_one) == 0) {
    stop("This time is not available in sun_clean. Check sun_clean$date.")
  }
  
  # 3. Empty shadow table
  all_shadows <- data.frame()
  
  # 4. Calculate shadows for all objects
  for(j in 1:nrow(shadow_objects)) {
    
    obj_one <- shadow_objects[j, ]
    
    shadow_df <- make_shadow(obj_one, sun_one)
    
    shadow_df$Object <- obj_one$Object
    
    all_shadows <- rbind(all_shadows, shadow_df)
  }
  
  # 5. Plot
  p +
    geom_polygon(
      data = all_shadows,
      aes(x = x, y = y, group = Object),
      fill = "grey40",
      alpha = 0.35,
      color = "grey20"
    ) +
    
    coord_fixed(
      xlim = c(-5, 30),
      ylim = c(-5, 40),
      expand = FALSE
    ) +
    
    labs(
      title = paste("Shadowfall at", wishtime),
      x = "Length [m]",
      y = "Width [m]"
    ) +
    
    theme_minimal() +
    
    theme(
      panel.grid = element_blank(),
      axis.line = element_line(color = "black"),
      axis.ticks = element_line(color = "black"),
      plot.title = element_text(
        hjust = 0.5,
        face = "bold",
        size = 24
      ),
      axis.title = element_text(size = 18),
      axis.text = element_text(size = 14),
      legend.position = "none"
    )
}

p2oc <- plot_shadows_at_time("14:00", objekte)

plot_shadows_at_time("21:00", objekte)

p2oc <- p2oc +
  theme(
    plot.margin = margin(25, 25, 25, 25)
  )

p_heat <- p_heat +
  theme(
    plot.margin = margin(25, 25, 25, 25)
  )

p_publish <- p2oc + p_heat

ggsave("Plot.jpg", p_publish, width = 14, height = 10, dpi =300 )

