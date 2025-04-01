{ 
  pkgs,
  lib,
  config,
  configVars,
  ... 
}: 

let
  app = "frigate";
in

{

  sops.secrets = {
    go2rtcRtspUser = {};
    go2rtcRtspPasswd = {};
    mqttFrigatePasswd = {};
  };

  environment = {
    etc."media/frigate".source = "/${config.drives.storageDrive1}/media/security-cameras";
    systemPackages = with pkgs; [ ffmpeg-full ];
  };

  hardware.coral.pcie.enable = true;

  systemd.services = {
    frigate.path = lib.mkBefore [ pkgs.ffmpeg-full ];
    go2rtc.environment = {
      GO2RTC_RTSP_USER = "${config.sops.secrets.go2rtcRtspUser.path}";
      GO2RTC_RTSP_PASSWD = "${config.sops.secrets.go2rtcRtspPasswd.path}";
    };
  };

  services = {

    nginx = {
      virtualHosts."${app}.${configVars.domain2}".listen = [{addr = "127.0.0.1"; port = 4395;}];
    };

    go2rtc = {
      enable = true;
      settings = {
        ffmpeg.bin = lib.getExe pkgs.ffmpeg-full;
        api.listen = "127.0.0.1:1984";
        streams = {
          front = "rtsp://$GO2RTC_RTSP_USER:$GO2RTC_RTSP_PASSWD@${configVars.frontCameraIp}:554/s0";
          front-detect = "rtsp://$GO2RTC_RTSP_USER:$GO2RTC_RTSP_PASSWD@${configVars.frontCameraIp}:554/s2";
          garage = "rtsp://$GO2RTC_RTSP_USER:$GO2RTC_RTSP_PASSWD@${configVars.garageCameraIp}:554/s0";
          garage-detect = "rtsp://$GO2RTC_RTSP_USER:$GO2RTC_RTSP_PASSWD@${configVars.garageCameraIp}:554/s2";
          gym = "rtsp://$GO2RTC_RTSP_USER:$GO2RTC_RTSP_PASSWD@${configVars.gymCameraIp}:554/s0";
          gym-detect = "rtsp://$GO2RTC_RTSP_USER:$GO2RTC_RTSP_PASSWD@${configVars.gymCameraIp}:554/s2";
        };
        webrtc = {
          listen = ":8555/tcp";
          candidates = [
            "${configVars.aspenLanIp}:8555"
            #"${configVars.aspenTailscaleIp}:8555"
            #"stun:8555"
          ];
        };
      };
    };

    ${app} = {
      enable = true;
      hostname = "${app}.${configVars.domain2}";
      vaapiDriver = "nvidia";
      settings = {

        #environment_vars = {
        #  FRIGATE_RTSP_USER_FILE = "${config.sops.secrets.go2rtcRtspUser.path}";
        #  FRIGATE_RTSP_PASSWORD_FILE = "${config.sops.secrets.go2rtcRtspPasswd.path}";
        #  FRIGATE_MQTT_PASSWORD_FILE = "${config.sops.secrets.mqttFrigatePasswd.path}";
        #};

        auth.enabled = "false";

        #mqtt = {
        #  enabled = false;
        #  #enabled = true;
        #  #host = "127.0.0.1";
        #  #user = "frigate";
        #  #password = "{FRIGATE_MQTT_PASSWORD}";
        #};

        logger = {
          default = "info";
        };

        cameras = {
          front = {
            enabled = true;
            ffmpeg.inputs = [
              {
                path = "rtsp://127.0.0.1:8554/front";
                input_args = "preset-rtsp-restream";
                roles = [ "record" ];
              }
              {
                path = "rtsp://127.0.0.1:8554/front-detect";
                input_args = "preset-rtsp-restream";
                roles = [ "detect" ];
              }
            ];
            detect = {
              enabled = true;
              width = 1024;
              height = 576;
              fps = 5;
            };
          };
          garage = {
            enabled = true;
            ffmpeg.inputs = [
              {
                path = "rtsp://127.0.0.1:8554/garage";
                input_args = "preset-rtsp-restream";
                roles = [ "record" ];
              }
              {
                path = "rtsp://127.0.0.1:8554/garage-detect";
                input_args = "preset-rtsp-restream";
                roles = [ "detect" ];
              }
            ];
            detect = {
              enabled = true;
              width = 1024;
              height = 576;
              fps = 5;
            };
          };
          gym = {
            enabled = true;
            ffmpeg.inputs = [
              {
                path = "rtsp://127.0.0.1:8554/gym";
                input_args = "preset-rtsp-restream";
                roles = [ "record" ];
              }
              {
                path = "rtsp://127.0.0.1:8554/gym-detect";
                input_args = "preset-rtsp-restream";
                roles = [ "detect" ];
              }
            ];
            detect = {
              enabled = true;
              width = 1024;
              height = 576;
              fps = 5;
            };
          };
        };

        ffmpeg = { # global ffmpeg configuration for all cameras
          hwaccel_args = "preset-nvidia-h264"; # adds nvidia gpu hardware acceleration
          output_args = {
            record = "preset-record-generic-audio-copy"; # adds audio to record streams
          };
        };

        birdseye = { # global birdseye configuration for all cameras
          enabled = true;
          restream = true; # restreams to http://192.168.1.2:8554/birdseye?
          mode = "continuous";
        };

        motion = { # global motion configuration for all cameras
          threshold = 25;
          contour_area = 40;
          delta_alpha = 0.2;
          frame_alpha = 0.2;
          frame_height = 50;
          improve_contrast = false;
        };

        record = { # global record configuration for all cameras
          enabled = true;
          retain = {
            days = 3;
            mode = "motion";
          };
          events = {
            pre_capture = 3;
            post_capture = 5;
            retain = {
              default = 3;
              mode = "active_objects";
            };
          };
        };

        detectors = { # global detector configuration for all cameras
          "${config.networking.hostName}-tpu" = {
            type = "edgetpu";
            device = "pci";
          };
        };

        snapshots = { # global snapshot configuration for all cameras, requires object detection turned on
          enabled = true;
          clean_copy = true;
          timestamp = true;
          bounding_box = true;
          crop = false;
          retain = {
            default = 3;
            objects = {
              person = 14;
            };
          };
        };
      
      };
    };

    #mosquitto = {
    #  listeners = [
    #    {
    #      users.frigate = {
    #        acl = [ "readwrite #" ];
    #        passwordFile = "${config.sops.secrets.mqttFrigatePasswd.path}";
    #      };
    #    }
    #  ];
    #};

    traefik.dynamicConfigOptions.http = {
      routers.${app} = {
        entrypoints = ["websecure"];
        rule = "Host(`${app}.${configVars.domain2}`)";
        service = "${app}";
        middlewares = [
          "secure-headers"
        ];
        tls = {
          certResolver = "cloudflareDns";
          options = "tls-13@file";
        };
      };
      services.${app} = {
        loadBalancer = {
          passHostHeader = true;
          servers = [
          {
            url = "http://127.0.0.1:4395";
          }
          ];
        };
      };
    };

  };

}