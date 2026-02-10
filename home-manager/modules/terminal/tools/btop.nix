# btop system monitor with CPU, memory, disk, network graphs.

{
  programs.btop = {
    enable = true;

    settings = {
      # Theme managed by Stylix
      theme_background = false;

      vim_keys = true;
      rounded_corners = false;
      shown_boxes = "cpu mem net proc";
      update_ms = 1000;

      proc_sorting = "cpu lazy";
      proc_tree = true;
      proc_per_core = false;
      proc_filter_kernel = true;

      cpu_single_graph = false;
      check_temp = true;
      show_cpu_freq = true;

      mem_graphs = true;
      swap_disk = true;
      show_disks = true;

      net_download = 100;
      net_upload = 100;
      net_auto = true;

      show_gpu_info = "On";
      nvml_measure_pcie_speeds = true;
    };
  };
}
