{
  pkgs,
  lib,
  ...
}:

{

  hardware.graphics = {
    enable = true;
    enable32Bit = true; # 32-bit OpenGL support for compatibility
    extraPackages = with pkgs; [
      intel-media-driver # VAAPI for Broadwell+ (Intel 5th gen and newer)
      intel-vaapi-driver # older Intel GPUs (fallback)
      libvdpau-va-gl # VDPAU backend for VA-API
    ];
  };

}
