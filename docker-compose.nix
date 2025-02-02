# Auto-generated using compose2nix v0.3.2-pre.
{ pkgs, lib, ... }:

{
  # Runtime
  virtualisation.podman = {
    enable = true;
    autoPrune.enable = true;
    dockerCompat = true;
    defaultNetwork.settings = {
      # Required for container networking to be able to use names.
      dns_enabled = true;
    };
  };

  # Enable container name DNS for non-default Podman networks.
  # https://github.com/NixOS/nixpkgs/issues/226365
  networking.firewall.interfaces."podman+".allowedUDPPorts = [ 53 ];

  virtualisation.oci-containers.backend = "podman";

  # Containers
  virtualisation.oci-containers.containers."recipesage_api" = {
    image = "julianpoy/recipesage-selfhost:api-v2.15.9";
    environment = {
      "BROWSERLESS_HOST" = "browserless";
      "BROWSERLESS_PORT" = "3000";
      "DATABASE_URL" = "postgresql://recipesage_selfhost:recipesage_selfhost@postgres:5432/recipesage_selfhost";
      "FILESYSTEM_STORAGE_PATH" = "/rs-media";
      "GRIP_KEY" = "changeme";
      "GRIP_URL" = "http://pushpin:5561/";
      "INGREDIENT_INSTRUCTION_CLASSIFIER_URL" = "http://ingredient-instruction-classifier:3000/";
      "NODE_ENV" = "selfhost";
      "POSTGRES_DB" = "recipesage_selfhost";
      "POSTGRES_HOST" = "postgres";
      "POSTGRES_LOGGING" = "false";
      "POSTGRES_PASSWORD" = "recipesage_selfhost";
      "POSTGRES_PORT" = "5432";
      "POSTGRES_SSL" = "false";
      "POSTGRES_USER" = "recipesage_selfhost";
      "SEARCH_PROVIDER" = "typesense";
      "STORAGE_TYPE" = "filesystem";
      "TYPESENSE_API_KEY" = "recipesage_selfhost";
      "TYPESENSE_NODES" = "[{\"host\": \"typesense\", \"port\": 8108, \"protocol\": \"http\"}]";
      "VERBOSE" = "false";
      "VERSION" = "selfhost";
    };
    volumes = [
      "recipesage_apimedia:/rs-media:rw"
    ];
    cmd = [ "sh" "-c" "npx prisma migrate deploy; npx nx seed prisma; npx ts-node --swc --project packages/backend/tsconfig.json packages/backend/src/bin/www" ];
    dependsOn = [
      "recipesage_browserless"
      "recipesage_postgres"
      "recipesage_pushpin"
      "recipesage_typesense"
    ];
    log-driver = "journald";
    extraOptions = [
      "--network-alias=api"
      "--network=recipesage_default"
    ];
  };
  systemd.services."podman-recipesage_api" = {
    serviceConfig = {
      Restart = lib.mkOverride 90 "always";
    };
    after = [
      "podman-network-recipesage_default.service"
      "podman-volume-recipesage_apimedia.service"
    ];
    requires = [
      "podman-network-recipesage_default.service"
      "podman-volume-recipesage_apimedia.service"
    ];
    partOf = [
      "podman-compose-recipesage-root.target"
    ];
    wantedBy = [
      "podman-compose-recipesage-root.target"
    ];
  };
  virtualisation.oci-containers.containers."recipesage_browserless" = {
    image = "browserless/chrome:1.61.0-puppeteer-21.4.1";
    environment = {
      "MAX_CONCURRENT_SESSIONS" = "3";
      "MAX_QUEUE_LENGTH" = "10";
    };
    log-driver = "journald";
    extraOptions = [
      "--network-alias=browserless"
      "--network=recipesage_default"
    ];
  };
  systemd.services."podman-recipesage_browserless" = {
    serviceConfig = {
      Restart = lib.mkOverride 90 "always";
    };
    after = [
      "podman-network-recipesage_default.service"
    ];
    requires = [
      "podman-network-recipesage_default.service"
    ];
    partOf = [
      "podman-compose-recipesage-root.target"
    ];
    wantedBy = [
      "podman-compose-recipesage-root.target"
    ];
  };
  virtualisation.oci-containers.containers."recipesage_postgres" = {
    image = "postgres:16";
    environment = {
      "POSTGRES_DB" = "recipesage_selfhost";
      "POSTGRES_PASSWORD" = "recipesage_selfhost";
      "POSTGRES_USER" = "recipesage_selfhost";
    };
    volumes = [
      "recipesage_postgresdata:/var/lib/postgresql/data:rw"
    ];
    log-driver = "journald";
    extraOptions = [
      "--network-alias=postgres"
      "--network=recipesage_default"
    ];
  };
  systemd.services."podman-recipesage_postgres" = {
    serviceConfig = {
      Restart = lib.mkOverride 90 "always";
    };
    after = [
      "podman-network-recipesage_default.service"
      "podman-volume-recipesage_postgresdata.service"
    ];
    requires = [
      "podman-network-recipesage_default.service"
      "podman-volume-recipesage_postgresdata.service"
    ];
    partOf = [
      "podman-compose-recipesage-root.target"
    ];
    wantedBy = [
      "podman-compose-recipesage-root.target"
    ];
  };
  virtualisation.oci-containers.containers."recipesage_proxy" = {
    image = "julianpoy/recipesage-selfhost-proxy:v4.0.0";
    ports = [
      "7270:80/tcp"
    ];
    dependsOn = [
      "recipesage_api"
      "recipesage_pushpin"
      "recipesage_static"
    ];
    log-driver = "journald";
    extraOptions = [
      "--network-alias=proxy"
      "--network=recipesage_default"
    ];
  };
  systemd.services."podman-recipesage_proxy" = {
    serviceConfig = {
      Restart = lib.mkOverride 90 "always";
    };
    after = [
      "podman-network-recipesage_default.service"
    ];
    requires = [
      "podman-network-recipesage_default.service"
    ];
    partOf = [
      "podman-compose-recipesage-root.target"
    ];
    wantedBy = [
      "podman-compose-recipesage-root.target"
    ];
  };
  virtualisation.oci-containers.containers."recipesage_pushpin" = {
    image = "julianpoy/pushpin:2023-09-17";
    environment = {
      "GRIP_KEY" = "changeme";
      "TARGET" = "api:3000";
    };
    cmd = [ "sed -i \"s/sig_key=changeme/sig_key=$GRIP_KEY/\" /etc/pushpin/pushpin.conf && echo \"* \${TARGET},over_http\" > /etc/pushpin/routes && pushpin --merge-output" ];
    log-driver = "journald";
    extraOptions = [
      "--entrypoint=[\"/bin/sh\", \"-c\"]"
      "--network-alias=pushpin"
      "--network=recipesage_default"
    ];
  };
  systemd.services."podman-recipesage_pushpin" = {
    serviceConfig = {
      Restart = lib.mkOverride 90 "always";
    };
    after = [
      "podman-network-recipesage_default.service"
    ];
    requires = [
      "podman-network-recipesage_default.service"
    ];
    partOf = [
      "podman-compose-recipesage-root.target"
    ];
    wantedBy = [
      "podman-compose-recipesage-root.target"
    ];
  };
  virtualisation.oci-containers.containers."recipesage_static" = {
    image = "julianpoy/recipesage-selfhost:static-v2.15.9";
    log-driver = "journald";
    extraOptions = [
      "--network-alias=static"
      "--network=recipesage_default"
    ];
  };
  systemd.services."podman-recipesage_static" = {
    serviceConfig = {
      Restart = lib.mkOverride 90 "always";
    };
    after = [
      "podman-network-recipesage_default.service"
    ];
    requires = [
      "podman-network-recipesage_default.service"
    ];
    partOf = [
      "podman-compose-recipesage-root.target"
    ];
    wantedBy = [
      "podman-compose-recipesage-root.target"
    ];
  };
  virtualisation.oci-containers.containers."recipesage_typesense" = {
    image = "typesense/typesense:0.24.1";
    volumes = [
      "recipesage_typesensedata:/data:rw"
    ];
    cmd = [ "--data-dir" "/data" "--api-key=recipesage_selfhost" "--enable-cors" ];
    log-driver = "journald";
    extraOptions = [
      "--network-alias=typesense"
      "--network=recipesage_default"
    ];
  };
  systemd.services."podman-recipesage_typesense" = {
    serviceConfig = {
      Restart = lib.mkOverride 90 "always";
    };
    after = [
      "podman-network-recipesage_default.service"
      "podman-volume-recipesage_typesensedata.service"
    ];
    requires = [
      "podman-network-recipesage_default.service"
      "podman-volume-recipesage_typesensedata.service"
    ];
    partOf = [
      "podman-compose-recipesage-root.target"
    ];
    wantedBy = [
      "podman-compose-recipesage-root.target"
    ];
  };

  # Networks
  systemd.services."podman-network-recipesage_default" = {
    path = [ pkgs.podman ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStop = "podman network rm -f recipesage_default";
    };
    script = ''
      podman network inspect recipesage_default || podman network create recipesage_default
    '';
    partOf = [ "podman-compose-recipesage-root.target" ];
    wantedBy = [ "podman-compose-recipesage-root.target" ];
  };

  # Volumes
  systemd.services."podman-volume-recipesage_apimedia" = {
    path = [ pkgs.podman ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      podman volume inspect recipesage_apimedia || podman volume create recipesage_apimedia --driver=local
    '';
    partOf = [ "podman-compose-recipesage-root.target" ];
    wantedBy = [ "podman-compose-recipesage-root.target" ];
  };
  systemd.services."podman-volume-recipesage_postgresdata" = {
    path = [ pkgs.podman ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      podman volume inspect recipesage_postgresdata || podman volume create recipesage_postgresdata --driver=local
    '';
    partOf = [ "podman-compose-recipesage-root.target" ];
    wantedBy = [ "podman-compose-recipesage-root.target" ];
  };
  systemd.services."podman-volume-recipesage_typesensedata" = {
    path = [ pkgs.podman ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      podman volume inspect recipesage_typesensedata || podman volume create recipesage_typesensedata --driver=local
    '';
    partOf = [ "podman-compose-recipesage-root.target" ];
    wantedBy = [ "podman-compose-recipesage-root.target" ];
  };

  # Root service
  # When started, this will automatically create all resources and start
  # the containers. When stopped, this will teardown all resources.
  systemd.targets."podman-compose-recipesage-root" = {
    unitConfig = {
      Description = "Root target generated by compose2nix.";
    };
    wantedBy = [ "multi-user.target" ];
  };
}
