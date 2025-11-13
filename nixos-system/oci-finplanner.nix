{ 
  config,
  lib,
  pkgs, 
  configVars,
  ... 
}: 

let

  app = "finplanner";
  finplannerPort = "7111";

  pythonKernelSpec = pkgs.runCommand "python-kernel-spec" {} ''
    mkdir -p $out/share/jupyter/kernels/python3
    cat > $out/share/jupyter/kernels/python3/kernel.json << EOF
    {
      "argv": [
        "${pkgs.python313}/bin/python",
        "-m",
        "ipykernel_launcher",
        "-f",
        "{connection_file}"
      ],
      "display_name": "Python 3",
      "language": "python",
      "metadata": {
        "debugger": true
      }
    }
    EOF
  '';
  
  # build the custom Jupyter image with all dependencies
  finplannerImage = pkgs.dockerTools.buildLayeredImage {
    name = "finplanner";
    tag = "latest";
    contents = with pkgs; [
      pythonKernelSpec
      python313
      python313Packages.jupyter-core
      python313Packages.jupyter
      python313Packages.jupyterlab
      python313Packages.ipykernel
      python313Packages.jupyter-client
      python313Packages.jupyterlab-server
      python313Packages.notebook
      python313Packages.nbformat
      python313Packages.nbconvert
      python313Packages.pandas
      python313Packages.numpy
      python313Packages.matplotlib
      python313Packages.scipy
      python313Packages.ipywidgets
      python313Packages.beancount
      python313Packages.pyyaml
      coreutils
      bash
    ];
    config = {
      Cmd = [ 
        "/bin/jupyter-lab"
        "--ip=0.0.0.0"
        "--port=${finplannerPort}"
        "--no-browser"
        "--allow-root"
        "--NotebookApp.token=''"
        "--NotebookApp.password=''"
      ];
      Env = [
        "JUPYTER_ENABLE_LAB=yes" # use JupyterLab interface (not classic)
      ];
      WorkingDir = "/work"; # default directory when Jupyter starts
      ExposedPorts = {
        "${finplannerPort}/tcp" = {};
      };
    };
  };

in

{

  # load the nix-built image into docker
  systemd.services."docker-load-${app}-image" = {
    description = "Load custom Jupyter Docker image from Nix";
    wantedBy = [ "docker-${app}.service" ];
    before = [ "docker-${app}.service" ];
    after = [ "docker.service" ];
    requires = [ "docker.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      ${pkgs.docker}/bin/docker load < ${finplannerImage}
    '';
  };

  virtualisation.oci-containers.containers."${app}" = {
    image = "finplanner:latest";
    autoStart = true;
    log-driver = "journald";
    volumes = [
      "/var/lib/nextcloud/data/Chris Bond/files/Bond Family/Financial/bond-ledger/finplanner:/work"
      "/var/lib/nextcloud/data/Chris Bond/files/Bond Family/Financial/bond-ledger:/beancount:ro"
    ];
    extraOptions = [
      "--network=${app}"
      "--ip=${configVars.finplannerIp}"
      "--tty=true"
      "--stop-signal=SIGINT"
    ];
    labels = {
      "traefik.enable" = "true";
      "traefik.http.routers.${app}.entrypoints" = "websecure";
      "traefik.http.routers.${app}.rule" = "Host(`${app}.${configVars.domain2}`)";
      "traefik.http.routers.${app}.tls" = "true";
      "traefik.http.routers.${app}.tls.options" = "tls-13@file";
      "traefik.http.routers.${app}.middlewares" = "trusted-allow@file,secure-headers@file";
      "traefik.http.services.${app}.loadbalancer.server.port" = finplannerPort;
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
          "docker-load-${app}-image.service"
        ];
        requires = [
          "docker-network-${app}.service"
          "docker-load-${app}-image.service"
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
          docker network inspect ${app} || docker network create --subnet ${configVars.finplannerSubnet} --driver bridge --scope local --attachable ${app}
        '';
        partOf = ["docker-${app}-root.target"];
        wantedBy = ["docker-${app}-root.target"];
      };
    };
    targets."docker-${app}-root" = {
      unitConfig = {
        Description = "root target for docker-${app} with custom Nix-built image";
      };
      wantedBy = ["multi-user.target"];
    };
  }; 
  
}