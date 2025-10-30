{ 
  config,
  lib,
  pkgs, 
  configVars,
  dockerServiceRecoveryScript,
  ... 
}: 

let
  app = "librechat";
  app1 = "api"; # bind mount env, three volumes
  app2 = "mongodb"; # volume
  app3 = "meilisearch"; # volume
  app4 = "vectordb"; # volume
  app5 = "rag_api";
  borgCryptPasswdFile = "/run/secrets/borgCryptPasswd";
  recoveryPlan = {
    serviceName = "${app}";
    localRestoreRepoPath = "${config.backups.borgDir}/${config.networking.hostName}";
    cloudRestoreRepoPath = "${config.backups.borgCloudDir}/${config.networking.hostName}";
    restoreItems = [
      "/var/lib/docker/volumes/${app}-${app1}-images"
      "/var/lib/docker/volumes/${app}-${app1}-logs"
      "/var/lib/docker/volumes/${app}-${app1}-uploads"
      "/var/lib/docker/volumes/${app}-${app2}"
      "/var/lib/docker/volumes/${app}-${app3}"
      "/var/lib/docker/volumes/${app}-${app4}"
    ];
    stopServices = [ "docker-${app}-root.target" ];
    startServices = [ "docker-${app}-root.target" ];
  };
  recoverScript = dockerServiceRecoveryScript {
    serviceName = app;
    recoveryPlan = recoveryPlan;
  };
in

{

  environment = {
    systemPackages = with pkgs; [ recoverScript ];
    etc = {
      "${app}-${app1}-librechat.yaml" = {
        text = ''
          version: 1.2.8
          cache: true
          endpoints:
            anthropic:
              streamRate: 25
              titleModel: "current_model"
              titleModelParameters:
                temperature: 0.7
                top_p: 0.9
            custom:
              - name: "Ollama"
                apiKey: "ollama"
                baseURL: "http://192.168.1.2:11434/v1"
                models:
                  default:
                    - "mistral"
                  fetch: true
                titleConvo: true
                titleModel: "current_model"
                titleModelParameters:
                  temperature: 0.7
                  top_p: 0.9
                summarize: false
                summaryModel: "current_model"
                forcePrompt: false
                modelDisplayLabel: "Ollama"
        '';
          #memory:
          #  disabled: true
          #  personalize: true
          #  tokenLimit: 2000
          #  messageWindowSize: 4 
          #  validKeys:
          #    - "general_facts"
          #    - "communication_preferences"
          #    - "personal_interests"
          #    - "technical_context"
          #  agent:
          #    provider: "anthropic"
          #    model: "claude-sonnet-4-20250514"
          #    instructions: |
          #      Store memory using only the specified validKeys categories:
          #      - general_facts: Important facts about the user that provide useful context
          #      - communication_preferences: How the user prefers explanations, formats, detail level
          #      - personal_interests: Hobbies, interests, topics the user cares about (linux, NixOS, cooking, etc.)
          #      - technical_context: System details, development environment, coding preferences, NixOS setup
          #      Focus on information that will be helpful in future conversations across diverse topics. 
          #      Delete outdated or corrected information promptly.
          #    model_parameters:
          #      temperature: 0.2
          #      max_tokens: 1500
        mode = "0644";
      };
      "${app}-${app2}-init.sh" = {
        text = ''
          #!/bin/bash
          exec mongod --noauth
        '';
        mode = "0755";
      };
    };
  };

  backups.serviceHooks = {
    preHook = lib.mkAfter [ "systemctl stop docker-${app}-root.target" ];
    postHook = lib.mkAfter [ "systemctl start docker-${app}-root.target" ];
  };

  services.borgbackup.jobs."${config.networking.hostName}".paths = lib.mkAfter recoveryPlan.restoreItems;

  sops = {
    secrets = {
      borgCryptPasswd = {};
      librechatOpenaiApiKey = {};
      anthropicApiKey = {};
      librechatMeiliMasterKey = {};
      librechatCredsKey = {};
      librechatCredsIv = {};
      librechatJwtSecret = {};
      librechatJwtRefreshSecret = {};
    };
    templates = {
      "${app}-env" = {
        owner = "chris";
        group = "users";
        mode = "0440";
        content = ''
          
          #==================================================#
          #               Server Configuration               #
          #==================================================#
          
          HOST=0.0.0.0
          MONGO_URI=${app2}://${app}-${app2}:27017/LibreChat
          PORT=3080
          DOMAIN_CLIENT=https://librechat.opticon.dev
          DOMAIN_SERVER=https://librechat.opticon.dev
          NO_INDEX=true
          TRUST_PROXY=1
          
          #===============#
          # JSON Logging  #
          #===============#
          
          CONSOLE_JSON=false
          
          #===============#
          # Debug Logging #
          #===============#
          
          DEBUG_LOGGING=true
          DEBUG_CONSOLE=false
          
          #===================================================#
          #                     Endpoints                     #
          #===================================================#
          
          ENDPOINTS=anthropic,custom
          PROXY=
          
          #===================================#
          # Known Endpoints - librechat.yaml  #
          #===================================#
          
          # ANYSCALE_API_KEY=
          # APIPIE_API_KEY=
          # COHERE_API_KEY=
          # DEEPSEEK_API_KEY=
          # DATABRICKS_API_KEY=
          # FIREWORKS_API_KEY=
          # GROQ_API_KEY=
          # HUGGINGFACE_TOKEN=
          # MISTRAL_API_KEY=
          # OPENROUTER_KEY=
          # PERPLEXITY_API_KEY=
          # SHUTTLEAI_API_KEY=
          # TOGETHERAI_API_KEY=
          # UNIFY_API_KEY=
          # XAI_API_KEY=
          
          #============#
          # Anthropic  #
          #============#
          
          ANTHROPIC_API_KEY=${config.sops.placeholder.anthropicApiKey}
          ANTHROPIC_MODELS=claude-sonnet-4-5-20250929,claude-opus-4-1-20250805
          
          #============#
          # OpenAI     #
          #============#
          
          #OPENAI_API_KEY=${config.sops.placeholder.librechatOpenaiApiKey}
          #OPENAI_MODELS=
          #DEBUG_OPENAI=false
          
          #====================#
          #   Assistants API   #
          #====================#
          
          # ASSISTANTS_API_KEY=user_provided
          # ASSISTANTS_BASE_URL=
          # ASSISTANTS_MODELS=gpt-4o,gpt-4o-mini,gpt-3.5-turbo-0125,gpt-3.5-turbo-16k-0613,gpt-3.5-turbo-16k,gpt-3.5-turbo,gpt-4,gpt-4-0314,gpt-4-32k-0314,gpt-4-0613,gpt-3.5-turbo-0613,gpt-3.5-turbo-1106,gpt-4-0125-preview,gpt-4-turbo-preview,gpt-4-1106-preview
          
          #============#
          # Plugins    #
          #============#
          
          # PLUGIN_MODELS=gpt-4o,gpt-4o-mini,gpt-4,gpt-4-turbo-preview,gpt-4-0125-preview,gpt-4-1106-preview,gpt-4-0613,gpt-3.5-turbo,gpt-3.5-turbo-0125,gpt-3.5-turbo-1106,gpt-3.5-turbo-0613
          DEBUG_PLUGINS=true
          CREDS_KEY=${config.sops.placeholder.librechatCredsKey}
          CREDS_IV=${config.sops.placeholder.librechatCredsIv}
          FLUX_API_BASE_URL=https://api.us1.bfl.ai
          
          #==================================================#
          #                Chat History Search               #
          #==================================================#
          
          SEARCH=true
          MEILI_HOST=http://${app}-${app3}:7700
          MEILI_NO_ANALYTICS=true
          MEILI_MASTER_KEY=${config.sops.placeholder.librechatMeiliMasterKey}
          
          #==================================================#
          #          Speech to Text & Text to Speech         #
          #==================================================#
          
          # STT_API_KEY=
          # TTS_API_KEY=
          
          #==================================================#
          #                        RAG                       #
          #==================================================#
          
          RAG_PORT=8000
          RAG_API_URL=http://${app}-${app5}:8000
          RAG_OPENAI_BASEURL=http://librechat-rag_api:8000
          RAG_OPENAI_API_KEY=${config.sops.placeholder.librechatOpenaiApiKey}
          RAG_USE_FULL_CONTEXT=false
          EMBEDDINGS_PROVIDER=openai
          EMBEDDINGS_MODEL=text-embedding-3-small
          
          #===================================================#
          #                    User System                    #
          #===================================================#
          
          #========================#
          # Moderation             #
          #========================#
          
          BAN_VIOLATIONS=true
          BAN_DURATION=1000 * 60 * 60 * 2
          BAN_INTERVAL=20
          LOGIN_VIOLATION_SCORE=1
          REGISTRATION_VIOLATION_SCORE=1
          CONCURRENT_VIOLATION_SCORE=1
          MESSAGE_VIOLATION_SCORE=1
          NON_BROWSER_VIOLATION_SCORE=20
          LOGIN_MAX=7
          LOGIN_WINDOW=5
          REGISTER_MAX=5
          REGISTER_WINDOW=60
          LIMIT_CONCURRENT_MESSAGES=true
          CONCURRENT_MESSAGE_MAX=2
          LIMIT_MESSAGE_IP=true
          MESSAGE_IP_MAX=40
          MESSAGE_IP_WINDOW=1
          LIMIT_MESSAGE_USER=false
          MESSAGE_USER_MAX=40
          MESSAGE_USER_WINDOW=1
          ILLEGAL_MODEL_REQ_SCORE=5
          
          #========================#
          # Registration and Login #
          #========================#
          
          ALLOW_EMAIL_LOGIN=true
          ALLOW_REGISTRATION=false
          ALLOW_SOCIAL_LOGIN=false
          ALLOW_SOCIAL_REGISTRATION=false
          ALLOW_PASSWORD_RESET=false
          ALLOW_ACCOUNT_DELETION=false
          ALLOW_UNVERIFIED_EMAIL_LOGIN=true
          SESSION_EXPIRY=1000 * 60 * 15
          REFRESH_TOKEN_EXPIRY=(1000 * 60 * 60 * 24) * 7
          JWT_SECRET=${config.sops.placeholder.librechatJwtSecret}
          JWT_REFRESH_SECRET=${config.sops.placeholder.librechatJwtRefreshSecret}
          
          #===================================================#
          #                        UI                         #
          #===================================================#
          
          APP_TITLE=Bond Private AI Interface 
          CUSTOM_FOOTER="Bond Private AI Interface"
          
          #=====================================================#
          #                  OpenWeather                        #
          #=====================================================#

          # OPENWEATHER_API_KEY=

          #====================================#
          # LibreChat Code Interpreter API     #
          #====================================#
          
          # https://code.librechat.ai
          # LIBRECHAT_CODE_API_KEY=your-key
          
          #======================#
          # Web Search           #
          #======================#

          SEARXNG_INSTANCE_URL=https://search.opticon.dev
          #FIRECRAWL_API_KEY=your_firecrawl_api_key
          #JINA_API_KEY=your_jina_api_key
          #COHERE_API_KEY=your_cohere_api_key
        '';
      };
      "${app3}-env" = {
        owner = "chris";
        group = "users";
        mode = "0440";
        content = ''
          MEILI_MASTER_KEY=${config.sops.placeholder.librechatMeiliMasterKey}
          MEILI_HOST=http://${app}-${app3}:7700
          MEILI_NO_ANALYTICS=true
        '';
      };
    };
  };

  # https://github.com/danny-avila/LibreChat/blob/main/docker-compose.yml
  virtualisation.oci-containers.containers = {

    "${app}-${app1}" = {
      image = "ghcr.io/danny-avila/librechat-dev:latest";
      autoStart = true;
      log-driver = "journald";
      dependsOn = [
        "${app}-${app2}"
        "${app}-${app5}"
      ];
      environmentFiles = [ config.sops.templates."${app}-env".path ];
      volumes = [ 
        "/etc/${app}-${app1}-librechat.yaml:/app/librechat.yaml"
        "${app}-${app1}-images:/app/client/public/images"
        "${app}-${app1}-uploads:/app/uploads" 
        "${app}-${app1}-logs:/app/api/logs" 
      ];
      extraOptions = [
        "--network=${app}"
        "--ip=${configVars.librechatApiIp}"
        "--tty=true"
        "--stop-signal=SIGINT"
      ];
      labels = {
        "traefik.enable" = "true";
        "traefik.http.routers.${app}.entrypoints" = "websecure";
        "traefik.http.routers.${app}.rule" = "Host(`librechat.${configVars.domain2}`)";
        "traefik.http.routers.${app}.tls" = "true";
        "traefik.http.routers.${app}.tls.options" = "tls-13@file";
        "traefik.http.routers.${app}.middlewares" = "trusted-allow@file,secure-headers@file";
        "traefik.http.services.${app}.loadbalancer.server.port" = "3080";
      };
    };

    "${app}-${app2}" = {
      image = "docker.io/mongo:7.0"; # https://hub.docker.com/_/mongo/tags
      autoStart = true;
      log-driver = "journald";
      volumes = [ 
        "${app}-${app2}:/data/db"
        "/etc/${app}-${app1}-init.sh:/docker-entrypoint-initdb.d/init-mongo.sh:ro"
      ];
      extraOptions = [
        "--tmpfs=/data/configdb"
        "--network=${app}"
        "--ip=${configVars.librechatMongoIp}"
        "--tty=true"
        "--stop-signal=SIGINT"
      ];
    };

    "${app}-${app3}" = {
      image = "docker.io/getmeili/meilisearch:v1.12.3"; # https://hub.docker.com/r/getmeili/meilisearch/tags
      autoStart = true;
      log-driver = "journald";
      environmentFiles = [ config.sops.templates."${app3}-env".path ];
      volumes = [ "${app}-${app3}:/meili_data" ];
      extraOptions = [
        "--network=${app}"
        "--ip=${configVars.librechatMeiliIp}"
        "--tty=true"
        "--stop-signal=SIGINT"
      ];
    };

    "${app}-${app4}" = {
      image = "docker.io/ankane/pgvector:v0.5.1"; # https://hub.docker.com/r/ankane/pgvector/tags
      autoStart = true;
      log-driver = "journald";
      environment = { 
        POSTGRES_DB = "mydatabase";
        POSTGRES_USER = "myuser";
        POSTGRES_PASSWORD= "mypassword";
      };
      volumes = [ "${app}-${app4}:/var/lib/postgresql/data" ];
      extraOptions = [
        "--network=${app}"
        "--ip=${configVars.librechatVectorIp}"
        "--tty=true"
        "--stop-signal=SIGINT"
      ];
    };

    "${app}-${app5}" = {
      image = "ghcr.io/danny-avila/librechat-rag-api-dev-lite:latest";
      autoStart = true;
      log-driver = "journald";
      dependsOn = [ "${app}-${app4}" ];
      environmentFiles = [ config.sops.templates."${app}-env".path ];
      environment = { 
        DB_HOST = "${app}-${app4}";
        RAG_PORT = "8000";
      };
      extraOptions = [
        "--network=${app}"
        "--ip=${configVars.librechatRagIp}"
        "--tty=true"
        "--stop-signal=SIGINT"
      ];
    };

  };

  systemd = {
    services = { 

      "docker-${app}-${app1}" = {
        serviceConfig = {
          Restart = lib.mkOverride 500 "always";
          RestartMaxDelaySec = lib.mkOverride 500 "1m";
          RestartSec = lib.mkOverride 500 "100ms";
          RestartSteps = lib.mkOverride 500 9;
        };
        after = [
          "docker-network-${app}.service"
          "docker-volume-${app}-${app1}-images.service"
          "docker-volume-${app}-${app1}-uploads.service"
          "docker-volume-${app}-${app1}-logs.service"
          "docker-chown-${app}-${app1}-images.service"
          "docker-chown-${app}-${app1}-uploads.service"
          "docker-chown-${app}-${app1}-logs.service"
          "docker-${app}-${app2}.service"
          "docker-${app}-${app5}.service"
        ];
        requires = [
          "docker-network-${app}.service"
          "docker-volume-${app}-${app1}-images.service"
          "docker-volume-${app}-${app1}-uploads.service"
          "docker-volume-${app}-${app1}-logs.service"
          "docker-${app}-${app2}.service"
          "docker-${app}-${app5}.service"
        ];
        partOf = [
          "docker-${app}-root.target"
        ];
        wantedBy = [
          "docker-${app}-root.target"
        ];
      };

      "docker-volume-${app}-${app1}-images" = {
        path = [pkgs.docker];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          docker volume inspect ${app}-${app1}-images || docker volume create ${app}-${app1}-images
        '';
        partOf = ["docker-${app}-root.target"];
        wantedBy = ["docker-${app}-root.target"];
      };
      "docker-volume-${app}-${app1}-uploads" = {
        path = [pkgs.docker];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          docker volume inspect ${app}-${app1}-uploads || docker volume create ${app}-${app1}-uploads
        '';
        partOf = ["docker-${app}-root.target"];
        wantedBy = ["docker-${app}-root.target"];
      };
      "docker-volume-${app}-${app1}-logs" = {
        path = [pkgs.docker];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          docker volume inspect ${app}-${app1}-logs || docker volume create ${app}-${app1}-logs
        '';
        partOf = ["docker-${app}-root.target"];
        wantedBy = ["docker-${app}-root.target"];
      };
      "docker-chown-${app}-${app1}-images" = {
        path = [ pkgs.docker ];
        script = ''
          docker run --rm -v ${app}-${app1}-images:/volume busybox chown -R 1000:1000 /volume
        '';
        wantedBy = [ "docker-${app}-root.target" ];
        after = [ "docker-volume-${app}-${app1}-images.service" ];
        before = [ "docker-${app}-${app1}.service" ];
        requires = [ "docker-volume-${app}-${app1}-images.service" ];
      };
      "docker-chown-${app}-${app1}-uploads" = {
        path = [ pkgs.docker ];
        script = ''
          docker run --rm -v ${app}-${app1}-uploads:/volume busybox chown -R 1000:1000 /volume
        '';
        wantedBy = [ "docker-${app}-root.target" ];
        after = [ "docker-volume-${app}-${app1}-uploads.service" ];
        before = [ "docker-${app}-${app1}.service" ];
        requires = [ "docker-volume-${app}-${app1}-uploads.service" ];
      };
      "docker-chown-${app}-${app1}-logs" = {
        path = [ pkgs.docker ];
        script = ''
          docker run --rm -v ${app}-${app1}-logs:/volume busybox chown -R 1000:1000 /volume
        '';
        wantedBy = [ "docker-${app}-root.target" ];
        after = [ "docker-volume-${app}-${app1}-logs.service" ];
        before = [ "docker-${app}-${app1}.service" ];
        requires = [ "docker-volume-${app}-${app1}-logs.service" ];
      };
      
      "docker-${app}-${app2}" = {
        serviceConfig = {
          Restart = lib.mkOverride 500 "always";
          RestartMaxDelaySec = lib.mkOverride 500 "1m";
          RestartSec = lib.mkOverride 500 "100ms";
          RestartSteps = lib.mkOverride 500 9;
        };
        after = [
          "docker-network-${app}.service"
          "docker-volume-${app}-${app2}.service"
        ];
        requires = [
          "docker-network-${app}.service"
          "docker-volume-${app}-${app2}.service"
        ];
        partOf = [
          "docker-${app}-root.target"
        ];
        wantedBy = [
          "docker-${app}-root.target"
        ];
      };

      "docker-volume-${app}-${app2}" = {
        path = [pkgs.docker];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          docker volume inspect ${app}-${app2} || docker volume create ${app}-${app2}
        '';
        partOf = ["docker-${app}-root.target"];
        wantedBy = ["docker-${app}-root.target"];
      };

      "docker-${app}-${app3}" = {
        serviceConfig = {
          Restart = lib.mkOverride 500 "always";
          RestartMaxDelaySec = lib.mkOverride 500 "1m";
          RestartSec = lib.mkOverride 500 "100ms";
          RestartSteps = lib.mkOverride 500 9;
        };
        after = [
          "docker-network-${app}.service"
          "docker-volume-${app}-${app3}.service"
        ];
        requires = [
          "docker-network-${app}.service"
          "docker-volume-${app}-${app3}.service"
        ];
        partOf = [
          "docker-${app}-root.target"
        ];
        wantedBy = [
          "docker-${app}-root.target"
        ];
      };
      
      "docker-volume-${app}-${app3}" = {
        path = [pkgs.docker];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          docker volume inspect ${app}-${app3} || docker volume create ${app}-${app3}
        '';
        partOf = ["docker-${app}-root.target"];
        wantedBy = ["docker-${app}-root.target"];
      };
      
      "docker-${app}-${app4}" = {
        serviceConfig = {
          Restart = lib.mkOverride 500 "always";
          RestartMaxDelaySec = lib.mkOverride 500 "1m";
          RestartSec = lib.mkOverride 500 "100ms";
          RestartSteps = lib.mkOverride 500 9;
        };
        after = [
          "docker-network-${app}.service"
          "docker-volume-${app}-${app4}.service"
        ];
        requires = [
          "docker-network-${app}.service"
          "docker-volume-${app}-${app4}.service"
        ];
        partOf = [
          "docker-${app}-root.target"
        ];
        wantedBy = [
          "docker-${app}-root.target"
        ];
      };
      
      "docker-volume-${app}-${app4}" = {
        path = [pkgs.docker];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          docker volume inspect ${app}-${app4} || docker volume create ${app}-${app4}
        '';
        partOf = ["docker-${app}-root.target"];
        wantedBy = ["docker-${app}-root.target"];
      };

      "docker-${app}-${app5}" = {
        serviceConfig = {
          Restart = lib.mkOverride 500 "always";
          RestartMaxDelaySec = lib.mkOverride 500 "1m";
          RestartSec = lib.mkOverride 500 "100ms";
          RestartSteps = lib.mkOverride 500 9;
        };
        after = [
          "docker-network-${app}.service"
          "docker-${app}-${app4}.service"
        ];
        requires = [
          "docker-network-${app}.service"
          "docker-${app}-${app4}.service"
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
          docker network inspect ${app} || docker network create --subnet ${configVars.librechatSubnet} --driver bridge --scope local --attachable ${app}
        '';
        partOf = ["docker-${app}-root.target"];
        wantedBy = ["docker-${app}-root.target"];
      };

    };
    targets."docker-${app}-root" = {
      unitConfig = {
        Description = "root target for ${app} container stack";
      };
      wantedBy = ["multi-user.target"];
    };
  }; 

}