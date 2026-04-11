.pragma library

function entries(home) {
  return [
    {
      id: "brave",
      name: "Brave",
      description: "Brave with Finland proxy",
      launcher: home + "/.local/bin/brave-proxy",
      icon: "world"
    },
    {
      id: "librewolf-banking",
      name: "LibreWolf Banking",
      description: "LibreWolf with Netherlands proxy",
      launcher: home + "/.local/bin/librewolf-banking",
      icon: "brand-firefox"
    },
    {
      id: "librewolf-personal",
      name: "LibreWolf Personal",
      description: "LibreWolf with Sweden proxy",
      launcher: home + "/.local/bin/librewolf-personal",
      icon: "brand-firefox"
    },
    {
      id: "librewolf-illegal",
      name: "LibreWolf Illegal",
      description: "LibreWolf with Switzerland proxy",
      launcher: home + "/.local/bin/librewolf-illegal",
      icon: "brand-firefox"
    },
    {
      id: "librewolf-i2pd",
      name: "LibreWolf I2P",
      description: "LibreWolf with I2P proxy",
      launcher: home + "/.local/bin/librewolf-i2pd",
      icon: "brand-firefox"
    },
    {
      id: "librewolf-shopping",
      name: "LibreWolf Shopping",
      description: "LibreWolf with Romania proxy",
      launcher: home + "/.local/bin/librewolf-shopping",
      icon: "brand-firefox"
    },
    {
      id: "librewolf-work",
      name: "LibreWolf Work",
      description: "LibreWolf with Germany proxy",
      launcher: home + "/.local/bin/librewolf-work",
      icon: "brand-firefox"
    }
  ];
}
