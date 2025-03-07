{ 
  pkgs, 
  config,
  configVars,
  ... 
}: 

let
  app = "frigate";
in

{

  sops.secrets = {
    frigateRtspUser = {};
    frigateRtspPasswd = {};
    mqttFrigatePasswd = {};
  };

  environment.etc."media/frigate".source = "/${config.drives.storageDrive1}/media/security-cameras";

  services = {

    nginx = {
      virtualHosts."${app}.${configVars.domain2}".listen = [{addr = "127.0.0.1"; port = 4413;}];
    };

    ${app} = {
      enable = true;
      hostname = "${app}.${configVars.domain2}"; # requires nginx in front?
      #hostname = "${configVars.aspenLanIp}";
      vaapiDriver = "nvidia";
      settings = {

        environment_vars = {
          FRIGATE_RTSP_USER_FILE = "${config.sops.secrets.frigateRtspUser.path}";
          FRIGATE_RTSP_PASSWORD_FILE = "${config.sops.secrets.frigateRtspPasswd.path}";
          FRIGATE_MQTT_PASSWORD_FILE = "${config.sops.secrets.mqttFrigatePasswd.path}";
        };

        #mqtt = {
        #  enabled = true;
        #  host = "127.0.0.1";
        #  user = "frigate";
        #  password = "{FRIGATE_MQTT_PASSWORD}";
        #};

        logger = {
          default = "info";
        };

        go2rtc = {
          streams = {
            front = [
              "rtsp://{FRIGATE_RTSP_USER}:{FRIGATE_RTSP_PASSWORD}@${configVars.frontCameraIp}:554/s0"
            ];
            front-detect = [
              "rtsp://{FRIGATE_RTSP_USER}:{FRIGATE_RTSP_PASSWORD}@${configVars.frontCameraIp}:554/s2"
            ];
            garage = [
              "rtsp://{FRIGATE_RTSP_USER}:{FRIGATE_RTSP_PASSWORD}@${configVars.garageCameraIp}:554/s0"
            ];
            garage-detect = [
              "rtsp://{FRIGATE_RTSP_USER}:{FRIGATE_RTSP_PASSWORD}@${configVars.garageCameraIp}:554/s2"
            ];
            gym = [
              "rtsp://{FRIGATE_RTSP_USER}:{FRIGATE_RTSP_PASSWORD}@${configVars.gymCameraIp}:554/s0"
            ];
            gym-detect = [
              "rtsp://{FRIGATE_RTSP_USER}:{FRIGATE_RTSP_PASSWORD}@${configVars.gymCameraIp}:554/s2"
            ];
          };
          webrtc = {
            candidates = [
              "${configVars.aspenLanIp}:8555"
              "stun:8555"
            ];
          };
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
              fps = 15;
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
              fps = 15;
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
              fps = 15;
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

    mosquitto = {
      listeners = [
        {
          users.frigate = {
            acl = [ "readwrite #" ];
            passwordFile = "${config.sops.secrets.mqttFrigatePasswd.path}";
          };
        }
      ];
    };

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
            url = "http://127.0.0.1:4413";
          }
          ];
        };
      };
    };

  };

}