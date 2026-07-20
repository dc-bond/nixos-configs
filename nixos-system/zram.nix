{ ... }:

{

  # Compressed in-RAM swap. On workstations with limited physical memory this
  # is the biggest single memory-pressure win: anonymous pages that would
  # otherwise spill to the disk swapfile get compressed (~3-4x with zstd) and
  # kept in RAM. Access is ~100x faster than disk swap and produces no disk wear.
  #
  # Sizing: memoryPercent = 50 gives up to 50% of RAM as *logical* zram, which
  # typically materializes as ~1/3 that in actual RAM cost after compression.
  # priority = 100 places zram above the on-disk swapfile (default priority -2)
  # so the kernel prefers zram; disk swap becomes cold-page overflow only.
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
    priority = 100;
  };

  # Sysctl tuning that only makes sense when zram is active.
  # - swappiness 180: on kernels >=5.8 the range is 0-200; a high value tells
  #   the kernel to evict anon pages (into zram) rather than drop file cache,
  #   because zram round-trips are cheaper than re-reading files from disk.
  # - page-cluster 0: disables swap read-ahead. zram is random-access RAM,
  #   so prefetching adjacent pages is wasted decompression work.
  # - watermark_boost_factor 0 + watermark_scale_factor 125: reduces the
  #   kernel's tendency to over-reserve free memory, giving apps more headroom
  #   before reclaim kicks in.
  boot.kernel.sysctl = {
    "vm.swappiness" = 180;
    "vm.page-cluster" = 0;
    "vm.watermark_boost_factor" = 0;
    "vm.watermark_scale_factor" = 125;
  };

}
