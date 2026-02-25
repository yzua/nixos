# System monitoring and diagnostic tools.
{ pkgsStable, ... }:

{
  home.packages = with pkgsStable; [
    # Benchmarking
    stress-ng
    sysbench

    # Container monitoring
    ctop

    # GPU monitoring
    nvitop
    nvtopPackages.nvidia # Lightweight C-based GPU monitor (complements nvitop)

    # Hardware information
    dmidecode
    hwinfo
    inxi
    lshw

    # Log analysis
    lnav

    # Memory analysis
    smem

    # Performance analysis
    inotify-tools
    perf-tools

    # Storage monitoring
    hdparm
    sdparm
  ];
}
