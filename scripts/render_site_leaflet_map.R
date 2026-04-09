#!/usr/bin/env Rscript

`%||%` <- function(x, y) {
  if (is.null(x) || length(x) == 0) y else x
}

script_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
script_path <- if (length(script_arg)) {
  sub("^--file=", "", script_arg[[1]])
} else {
  "."
}
pkg_root <- dirname(dirname(normalizePath(script_path, winslash = "/", mustWork = FALSE)))

readRenviron(file.path(pkg_root, ".Renviron"))

suppressPackageStartupMessages({
  library(heuristR)
  library(sf)
  library(leaflet)
  library(htmlwidgets)
})

base_url <- Sys.getenv("HEURISTR_TEST_BASE_URL")
database <- Sys.getenv("HEURISTR_TEST_DB")
username <- Sys.getenv("HEURIST_USERNAME")
password <- Sys.getenv("HEURIST_PASSWORD")

if (!nzchar(base_url) || !nzchar(database) || !nzchar(username) || !nzchar(password)) {
  stop("HEURISTR_TEST_BASE_URL, HEURISTR_TEST_DB, HEURIST_USERNAME, and HEURIST_PASSWORD must be set.")
}

session <- heurist_session(base_url, database)
session <- heurist_login(session, username, password)

rectypes <- heurist_rectypes(session)
site <- Filter(function(x) identical(x$rty_Name %||% "", "Site"), rectypes)
if (!length(site)) {
  stop("No Site rectype found in database.")
}

sites_sf <- heurist_find_records(
  session,
  paste0("t:", site[[1]]$rty_ID),
  as_sf = TRUE
)

sites_sf <- sites_sf[!sf::st_is_empty(sites_sf), ]
sites_sf <- sf::st_transform(sites_sf, 4326)
point_sf <- sites_sf[as.character(sf::st_geometry_type(sites_sf)) == "POINT", ]

out_dir <- file.path(pkg_root, "inst", "examples")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

geojson_path <- file.path(out_dir, paste0(database, "_sites.geojson"))
html_path <- file.path(out_dir, paste0(database, "_sites_leaflet_map.html"))
widget_path <- file.path(out_dir, paste0(database, "_sites_leaflet_widget.html"))

suppressWarnings(sf::st_write(sites_sf, geojson_path, driver = "GeoJSON", delete_dsn = TRUE, quiet = TRUE))

bbox <- sf::st_bbox(sites_sf)

html <- sprintf(
'<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>%s Site Map</title>
    <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
    <style>
      body { margin: 0; font-family: sans-serif; background: #f8f9fa; color: #212529; }
      .wrap { padding: 16px; }
      h1 { margin: 0 0 8px; font-size: 1.4rem; }
      p { margin: 0 0 12px; }
      #map { height: calc(100vh - 170px); min-height: 520px; border: 1px solid #ced4da; background: #ffffff; }
      .note { color: #495057; font-size: 0.95rem; }
    </style>
  </head>
  <body>
    <div class="wrap">
      <h1>%s Site Map</h1>
      <p>Generated from Heurist database <strong>%s</strong>. Showing %s site records with spatial geometry.</p>
      <p class="note">This local HTML version intentionally omits a remote basemap so it works when opened directly from disk. Open the companion widget file or serve this directory over HTTP if you want a tiled basemap.</p>
      <div id="map"></div>
    </div>
    <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
    <script>
      const map = L.map("map", { preferCanvas: true });
      const bounds = [[%f, %f], [%f, %f]];
      map.fitBounds(bounds, { padding: [20, 20] });

      fetch("%s")
        .then((response) => response.json())
        .then((data) => {
          const layer = L.geoJSON(data, {
            pointToLayer: (feature, latlng) => L.circleMarker(latlng, {
              radius: 4,
              weight: 1,
              color: "#212529",
              fillColor: "#0d6efd",
              fillOpacity: 0.75
            }),
            onEachFeature: (feature, layer) => {
              const props = feature.properties || {};
              const title = props.rec_Title || props.rec_ID || "Untitled record";
              const id = props.rec_ID ? `<div><strong>ID:</strong> ${props.rec_ID}</div>` : "";
              layer.bindPopup(`<strong>${title}</strong>${id}`);
            }
          }).addTo(map);

          if (layer.getBounds().isValid()) {
            map.fitBounds(layer.getBounds(), { padding: [20, 20] });
          }
        });
    </script>
  </body>
</html>',
    database,
    database,
    database,
    nrow(sites_sf),
    bbox[2], bbox[1], bbox[4], bbox[3],
    basename(geojson_path)
)

writeLines(html, html_path)

widget <- leaflet::leaflet(point_sf) |>
  leaflet::addProviderTiles(leaflet::providers$CartoDB.Positron) |>
  leaflet::addCircleMarkers(
    radius = 4,
    weight = 1,
    color = "#212529",
    fillColor = "#0d6efd",
    fillOpacity = 0.75,
    popup = ~sprintf("<strong>%s</strong><div><strong>ID:</strong> %s</div>", rec_Title, rec_ID)
  )

htmlwidgets::saveWidget(widget, widget_path, selfcontained = TRUE)

cat("GeoJSON:", geojson_path, "\n")
cat("HTML:", html_path, "\n")
cat("Widget:", widget_path, "\n")
