# Laptop kernel params for backlight.

_:

{
  boot.kernelParams = [
    "acpi_backlight=native" # Required for thinkpad_acpi backlight save/load
  ];
}
