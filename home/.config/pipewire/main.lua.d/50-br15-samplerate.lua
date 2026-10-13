alsa_monitor.rules = {
  {
    matches = {
      {
        { "node.name", "equals", "alsa_card.usb-GuangZhou_FIIO_Electronics_Co._Ltd_FIIO_BTR15-00" },
      },
    },
    apply_properties = {
      ["audio.rate"] = 96000,
    },
  },
}
