# PC host-specific tuning (IO, filesystem).

_: {
  # I/O scheduler and SATA link policy for this host.
  # - Non-rotational disks get mq-deadline for low latency, EXCEPT sdb which needs BFQ
  #   because the KINGSTON SA400S37480G is DRAM-less and mq-deadline lets bulk writes
  #   monopolize the device, causing 1+ second I/O stalls under load.
  # - Rotational disks get BFQ for fair bandwidth distribution.
  # - SATA links forced to max_performance to avoid ALPM/DIPM-related freezes.
  services.udev.extraRules = ''
    ACTION=="add|change", KERNEL=="sdb", ATTR{queue/scheduler}="bfq"
    ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="mq-deadline"
    ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="bfq"
    ACTION=="add|change", SUBSYSTEM=="scsi_host", KERNEL=="host*", ATTR{link_power_management_policy}="max_performance"
  '';
}
