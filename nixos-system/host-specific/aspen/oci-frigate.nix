{ 
  config,
  lib,
  pkgs, 
  configVars,
  ... 
}: 

let
  app = "frigate";
in

{

  sops = {
    secrets = {
      frigateRtspUser = {};
      frigateRtspPasswd = {};
      frigateMqttUser = {};
      frigateMqttPasswd = {};
    };
    templates = {
      "${app}-env".content = ''
        FRIGATE_RTSP_USER=${config.sops.placeholder.frigateRtspUser}
        FRIGATE_RTSP_PASSWORD=${config.sops.placeholder.frigateRtspPasswd}
        FRIGATE_MQTT_USER=${config.sops.placeholder.frigateMqttUser}
        FRIGATE_MQTT_PASSWORD=${config.sops.placeholder.frigateMqttPasswd}
        NVIDIA_VISIBLE_DEVIDES=all
        NVIDIA_DRIVER_CAPABILITIES=compute,utility,video
      '';
    };
  };

  environment = {
    #etc."media/frigate".source = "/${config.drives.storageDrive1}/media/security-cameras";
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
  
  virtualisation.oci-containers.containers = {

    "${app}" = {
      image = "ghcr.io/blackeblackshear/${app}:0.15.0"; # https://github.com/blakeblackshear/frigate/releases
      autoStart = true;
      environmentFiles = [ config.sops.templates."${app}-env".path ];
      log-driver = "journald";
      ports = [
        "5000:5000/tcp" # main web view port
        "8554:8554/tcp" # RTSP feeds
        "8555:8555/tcp" # WebRTC over tcp
        "8555:8555/udp" # WebRTC over udp
      ];
      volumes = [ 
        "${app}:/etc" 
      ]; 
      extraOptions = [
        "--network=${app}"
        "--ip=${configVars.frigateIp}"
        "--tty=true"
        "--stop-signal=SIGINT"
      ];
      #labels = {
      #  "traefik.enable" = "true";
      #  "traefik.http.routers.${app}.entrypoints" = "websecure";
      #  "traefik.http.routers.${app}.rule" = "Host(`${app}.${configVars.domain2}`)";
      #  "traefik.http.routers.${app}.tls" = "true";
      #  "traefik.http.routers.${app}.tls.options" = "tls-13@file";
      #  "traefik.http.routers.${app}.middlewares" = "secure-headers@file";
      #  "traefik.http.services.${app}.loadbalancer.server.port" = "5000"; # port for web view
      #};
    };

    "${app2}" = {
      image = "docker.io/mvance/${app2}:1.15.0"; # https://github.com/MatthewVance/unbound-docker
      autoStart = true;
      log-driver = "journald";
      volumes = [ "${app2}:/opt/unbound/etc/unbound" ];
      extraOptions = [
        "--network=${app}"
        "--ip=${configVars.unboundIp}"
        "--tty=true"
        "--stop-signal=SIGINT"
      ];
    };

  };

  systemd = {
    services = { 

      "docker-${app}" = {
        serviceConfig = {
          Restart = lib.mkOverride 500 "always";
          RestartMaxDelaySec = lib.mkOverride 500 "1m";
          RestartSec = lib.mkOverride 500 "100ms";
          RestartSteps = lib.mkOverride 500 9;
        };
        after = [
          "docker-network-${app}.service"
          "docker-volume-${app}.service"
        ];
        requires = [
          "docker-network-${app}.service"
          "docker-volume-${app}.service"
        ];
        partOf = [
          "docker-${app}-root.target"
        ];
        wantedBy = [
          "docker-${app}-root.target"
        ];
      };
      "docker-network-${app}" = {
        path = [pkgs.docker];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStop = "${pkgs.docker}/bin/docker network rm -f ${app}";
        };
        script = ''
          docker network inspect ${app} || docker network create --subnet ${configVars.piholeSubnet} --driver bridge --scope local --attachable ${app}
        '';
        partOf = ["docker-${app}-root.target"];
        wantedBy = ["docker-${app}-root.target"];
      };
      "docker-volume-${app}" = {
        path = [pkgs.docker];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          docker volume inspect ${app} || docker volume create ${app}
        '';
        partOf = ["docker-${app}-root.target"];
        wantedBy = ["docker-${app}-root.target"];
      };
      
      "docker-${app2}" = {
        serviceConfig = {
          Restart = lib.mkOverride 500 "always";
          RestartMaxDelaySec = lib.mkOverride 500 "1m";
          RestartSec = lib.mkOverride 500 "100ms";
          RestartSteps = lib.mkOverride 500 9;
        };
        after = [
          "docker-${app}.service"
          "docker-volume-${app2}.service"
        ];
        requires = [
          "docker-${app}.service"
          "docker-volume-${app2}.service"
        ];
        partOf = [
          "docker-${app}-root.target"
        ];
        wantedBy = [
          "docker-${app}-root.target"
        ];
      };
      "docker-volume-${app2}" = {
        path = [pkgs.docker];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          docker volume inspect ${app2} || docker volume create ${app2}
        '';
        partOf = ["docker-${app}-root.target"];
        wantedBy = ["docker-${app}-root.target"];
      };

    };
    targets."docker-${app}-root" = {
      unitConfig = {
        Description = "root target for docker-${app} and docker-${app2}";
      };
      wantedBy = ["multi-user.target"];
    };
  }; 

}


    #go2rtc = {
    #  enable = true;
    #  settings = {
    #    ffmpeg.bin = lib.getExe pkgs.ffmpeg-full;
    #    api.listen = "127.0.0.1:1984";
    #    streams = {
    #      front = "rtsp://$GO2RTC_RTSP_USER:$GO2RTC_RTSP_PASSWD@${configVars.frontCameraIp}:554/s0";
    #      front-detect = "rtsp://$GO2RTC_RTSP_USER:$GO2RTC_RTSP_PASSWD@${configVars.frontCameraIp}:554/s2";
    #      garage = "rtsp://$GO2RTC_RTSP_USER:$GO2RTC_RTSP_PASSWD@${configVars.garageCameraIp}:554/s0";
    #      garage-detect = "rtsp://$GO2RTC_RTSP_USER:$GO2RTC_RTSP_PASSWD@${configVars.garageCameraIp}:554/s2";
    #      gym = "rtsp://$GO2RTC_RTSP_USER:$GO2RTC_RTSP_PASSWD@${configVars.gymCameraIp}:554/s0";
    #      gym-detect = "rtsp://$GO2RTC_RTSP_USER:$GO2RTC_RTSP_PASSWD@${configVars.gymCameraIp}:554/s2";
    #    };
    #    webrtc = {
    #      listen = ":8555/tcp";
    #      candidates = [
    #        "${configVars.aspenLanIp}:8555"
    #        #"${configVars.aspenTailscaleIp}:8555"
    #        #"stun:8555"
    #      ];
    #    };
    #  };
    #};

    #${app} = {
    #  enable = true;
    #  hostname = "${app}.${configVars.domain2}";
    #  vaapiDriver = "nvidia";
    #  settings = {

    #    #environment_vars = {
    #    #  FRIGATE_RTSP_USER_FILE = "${config.sops.secrets.go2rtcRtspUser.path}";
    #    #  FRIGATE_RTSP_PASSWORD_FILE = "${config.sops.secrets.go2rtcRtspPasswd.path}";
    #    #  FRIGATE_MQTT_PASSWORD_FILE = "${config.sops.secrets.mqttFrigatePasswd.path}";
    #    #};

    #    auth.enabled = "false";

    #    #mqtt = {
    #    #  enabled = false;
    #    #  #enabled = true;
    #    #  #host = "127.0.0.1";
    #    #  #user = "frigate";
    #    #  #password = "{FRIGATE_MQTT_PASSWORD}";
    #    #};

    #    logger = {
    #      default = "info";
    #    };

    #    cameras = {
    #      front = {
    #        enabled = true;
    #        ffmpeg.inputs = [
    #          {
    #            path = "rtsp://127.0.0.1:8554/front";
    #            input_args = "preset-rtsp-restream";
    #            roles = [ "record" ];
    #          }
    #          {
    #            path = "rtsp://127.0.0.1:8554/front-detect";
    #            input_args = "preset-rtsp-restream";
    #            roles = [ "detect" ];
    #          }
    #        ];
    #        detect = {
    #          enabled = true;
    #          width = 1024;
    #          height = 576;
    #          fps = 5;
    #        };
    #      };
    #      garage = {
    #        enabled = true;
    #        ffmpeg.inputs = [
    #          {
    #            path = "rtsp://127.0.0.1:8554/garage";
    #            input_args = "preset-rtsp-restream";
    #            roles = [ "record" ];
    #          }
    #          {
    #            path = "rtsp://127.0.0.1:8554/garage-detect";
    #            input_args = "preset-rtsp-restream";
    #            roles = [ "detect" ];
    #          }
    #        ];
    #        detect = {
    #          enabled = true;
    #          width = 1024;
    #          height = 576;
    #          fps = 5;
    #        };
    #      };
    #      gym = {
    #        enabled = true;
    #        ffmpeg.inputs = [
    #          {
    #            path = "rtsp://127.0.0.1:8554/gym";
    #            input_args = "preset-rtsp-restream";
    #            roles = [ "record" ];
    #          }
    #          {
    #            path = "rtsp://127.0.0.1:8554/gym-detect";
    #            input_args = "preset-rtsp-restream";
    #            roles = [ "detect" ];
    #          }
    #        ];
    #        detect = {
    #          enabled = true;
    #          width = 1024;
    #          height = 576;
    #          fps = 5;
    #        };
    #      };
    #    };

    #    ffmpeg = { # global ffmpeg configuration for all cameras
    #      hwaccel_args = "preset-nvidia-h264"; # adds nvidia gpu hardware acceleration
    #      output_args = {
    #        record = "preset-record-generic-audio-copy"; # adds audio to record streams
    #      };
    #    };

    #    birdseye = { # global birdseye configuration for all cameras
    #      enabled = true;
    #      restream = true; # restreams to http://192.168.1.2:8554/birdseye?
    #      mode = "continuous";
    #    };

    #    motion = { # global motion configuration for all cameras
    #      threshold = 25;
    #      contour_area = 40;
    #      delta_alpha = 0.2;
    #      frame_alpha = 0.2;
    #      frame_height = 50;
    #      improve_contrast = false;
    #    };

    #    record = { # global record configuration for all cameras
    #      enabled = true;
    #      retain = {
    #        days = 3;
    #        mode = "motion";
    #      };
    #      events = {
    #        pre_capture = 3;
    #        post_capture = 5;
    #        retain = {
    #          default = 3;
    #          mode = "active_objects";
    #        };
    #      };
    #    };

    #    detectors = { # global detector configuration for all cameras
    #      "${config.networking.hostName}-tpu" = {
    #        type = "edgetpu";
    #        device = "pci";
    #      };
    #    };

    #    snapshots = { # global snapshot configuration for all cameras, requires object detection turned on
    #      enabled = true;
    #      clean_copy = true;
    #      timestamp = true;
    #      bounding_box = true;
    #      crop = false;
    #      retain = {
    #        default = 3;
    #        objects = {
    #          person = 14;
    #        };
    #      };
    #    };
    #  
    #  };
    #};