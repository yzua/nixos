# Server stats configuration for the Glance dashboard server-stats widget.

[
  {
    type = "local";
    name = "PC";
    mountpoints = {
      "/" = {
        name = "Root";
      };
      "/home" = {
        name = "Home";
      };
    };
  }
]
