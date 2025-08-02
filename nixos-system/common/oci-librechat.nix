{ 
  config,
  lib,
  pkgs, 
  configVars,
  ... 
}: 

let
  app = "librechat";
  app1 = "api"; # bind mount env, three volumes
  app2 = "mongodb"; # volume
  app3 = "meilisearch"; # volume
  app4 = "vectordb"; # volume
  app5 = "rag_api";
in

{

  environment.etc."${app}-${app2}-init.sh" = {
    text = ''
      #!/bin/bash
      exec mongod --noauth
    '';
    mode = "0755";
  };

  sops = {
    secrets = {
      librechatOpenaiApiKey = {};
      librechatAnthropicApiKey = {};
    };
    templates = {
      "${app}-env" = {
        owner = "chris";
        group = "users";
        mode = "0440";
        content = ''
          #=====================================================================#
          #                       LibreChat Configuration                       #
          #=====================================================================#
          # Please refer to the reference documentation for assistance          #
          # with configuring your LibreChat environment.                        #
          #                                                                     #
          # https://www.librechat.ai/docs/configuration/dotenv                  #
          #=====================================================================#
          
          #==================================================#
          #               Server Configuration               #
          #==================================================#
          
          PORT=3080
          DOMAIN_CLIENT=https://bond-ai.opticon.dev
          DOMAIN_SERVER=https://bond-ai.opticon.dev
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
          
          ENDPOINTS=openAI,anthropic
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
          
          ANTHROPIC_API_KEY=${config.sops.placeholder.librechatAnthropicApiKey}
          ANTHROPIC_MODELS=claude-opus-4-20250514,claude-sonnet-4-20250514,claude-3-5-haiku-20241022
          
          #============#
          # OpenAI     #
          #============#
          
          OPENAI_API_KEY=${config.sops.placeholder.librechatOpenaiApiKey}
          OPENAI_MODELS=gpt-4.1,gpt-4o-mini
          DEBUG_OPENAI=false
          
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
          CREDS_KEY=f34be427ebb29de8d88c107a71546019685ed8b241d8f2ed00c3df97ad2566f0
          CREDS_IV=e2341419ec3dd3d19b13a1a87fafcbfb
          FLUX_API_BASE_URL=https://api.us1.bfl.ai
          
          #==================================================#
          #                Chat History Search               #
          #==================================================#
          
          SEARCH=true
          MEILI_NO_ANALYTICS=true
          #MEILI_HOST=http://0.0.0.0:7700
          MEILI_MASTER_KEY=DrhYf7zENyR6AlUCKmnz0eYASOQdl6zxH7s7MKFSfFCt
          
          #==================================================#
          #          Speech to Text & Text to Speech         #
          #==================================================#
          
          # STT_API_KEY=
          # TTS_API_KEY=
          
          #==================================================#
          #                        RAG                       #
          #==================================================#
          
          # RAG_OPENAI_BASEURL=
          # RAG_OPENAI_API_KEY=
          # RAG_USE_FULL_CONTEXT=
          # EMBEDDINGS_PROVIDER=openai
          # EMBEDDINGS_MODEL=text-embedding-3-small
          
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
          ALLOW_REGISTRATION=true
          ALLOW_SOCIAL_LOGIN=false
          ALLOW_SOCIAL_REGISTRATION=false
          ALLOW_PASSWORD_RESET=false
          # ALLOW_ACCOUNT_DELETION=true # note: enabled by default if omitted/commented out
          ALLOW_UNVERIFIED_EMAIL_LOGIN=true
          SESSION_EXPIRY=1000 * 60 * 15
          REFRESH_TOKEN_EXPIRY=(1000 * 60 * 60 * 24) * 7
          JWT_SECRET=16f8c0ef4a5d391b26034086c628469d3f9f497f08163ab9b40137092f2909ef
          JWT_REFRESH_SECRET=eaa5191f2914e30b9387fd84e254e4ba6fc51b4654968a9b0803b456a54b8418
          
          #===================================================#
          #                        UI                         #
          #===================================================#
          
          APP_TITLE=Bond AI 
          CUSTOM_FOOTER="Bond AI"
          
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
      environment = { 
        HOST = "0.0.0.0";
        MONGO_URI = "${app2}://${app}-${app2}:27017/LibreChat";
        MEILI_HOST = "http://${app}-${app3}:7700";
        RAG_PORT = "8000";
        RAG_API_URL = "http://${app}-${app5}:8000";
      };
      volumes = [ 
        #"/run/secrets/rendered/${app}-env:/app/.env" # bind mount rendered sops env file to /app/.env inside container
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
        "traefik.http.routers.${app}.rule" = "Host(`bond-ai.${configVars.domain2}`)";
        "traefik.http.routers.${app}.tls" = "true";
        "traefik.http.routers.${app}.tls.options" = "tls-13@file";
        "traefik.http.routers.${app}.middlewares" = "secure-headers@file";
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
      environment = { 
        MEILI_HOST = "http://${app}-${app3}:7700";
        MEILI_NO_ANALYTICS = "true";
        MEILI_MASTER_KEY = "DrhYf7zENyR6AlUCKmnz0eYASOQdl6zxH7s7MKFSfFCt";
      };
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