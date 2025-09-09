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

  environment.etc = {
    "${app}-${app1}-librechat.yaml" = {
      text = ''
        version: 1.2.8
        cache: true
        interface:
          # MCP Servers UI configuration
          mcpServers:
            placeholder: 'MCP Servers'
            
          # Privacy policy settings
          privacyPolicy:
            externalUrl: 'https://librechat.ai/privacy-policy'
            openNewTab: true
         
          # Terms of service
          termsOfService:
            externalUrl: 'https://librechat.ai/tos'
            openNewTab: true
         
        registration:
          socialLogins: ["discord", "facebook", "github", "google", "openid"]
         
        endpoints:
          custom:
         
            # Anyscale
            - name: "Anyscale"
              apiKey: ""
              baseURL: "https://api.endpoints.anyscale.com/v1"
              models:
                default: [
                  "meta-llama/Llama-2-7b-chat-hf",
                  ]
                fetch: true
              titleConvo: true
              titleModel: "meta-llama/Llama-2-7b-chat-hf"
              summarize: false
              summaryModel: "meta-llama/Llama-2-7b-chat-hf"
              forcePrompt: false
              modelDisplayLabel: "Anyscale"
         
            # APIpie
            - name: "APIpie"
              apiKey: ""
              baseURL: "https://apipie.ai/v1/"
              models:
                default: [
                  "gpt-4",
                  "gpt-4-turbo",
                  "gpt-3.5-turbo",
                  "claude-3-opus",
                  "claude-3-sonnet",
                  "claude-3-haiku",
                  "llama-3-70b-instruct",
                  "llama-3-8b-instruct",
                  "gemini-pro-1.5",
                  "gemini-pro",
                  "mistral-large",
                  "mistral-medium",
                  "mistral-small",
                  "mistral-tiny",
                  "mixtral-8x22b",
                  ]
                fetch: false
              titleConvo: true
              titleModel: "gpt-3.5-turbo"
              dropParams: ["stream"]
         
            #cohere
            - name: "cohere"
              apiKey: ""
              baseURL: "https://api.cohere.ai/v1"
              models:
                default: ["command-r","command-r-plus","command-light","command-light-nightly","command","command-nightly"]
                fetch: false
              modelDisplayLabel: "cohere"
              titleModel: "command"
              dropParams: ["stop", "user", "frequency_penalty", "presence_penalty", "temperature", "top_p"]
         
            # Fireworks
            - name: "Fireworks"
              apiKey: ""
              baseURL: "https://api.fireworks.ai/inference/v1"
              models:
                default: [
                  "accounts/fireworks/models/mixtral-8x7b-instruct",
                  ]
                fetch: true
              titleConvo: true
              titleModel: "accounts/fireworks/models/llama-v2-7b-chat"
              summarize: false
              summaryModel: "accounts/fireworks/models/llama-v2-7b-chat"
              forcePrompt: false
              modelDisplayLabel: "Fireworks"
              dropParams: ["user"]
          
            # groq
            - name: "groq"
              apiKey: ""
              baseURL: "https://api.groq.com/openai/v1/"
              models:
                default: [
                  "llama2-70b-4096",
                  "llama3-70b-8192",
                  "llama3-8b-8192",
                  "mixtral-8x7b-32768",
                  "gemma-7b-it",
                  ]
                fetch: false
              titleConvo: true
              titleModel: "mixtral-8x7b-32768"
              modelDisplayLabel: "groq"
         
            # Mistral AI API
            - name: "Mistral"
              apiKey: ""
              baseURL: "https://api.mistral.ai/v1"
              models:
                default: [
                  "mistral-tiny",
                  "mistral-small",
                  "mistral-medium",
                  "mistral-large-latest"
                  ]
                fetch: true
              titleConvo: true
              titleModel: "mistral-tiny"
              modelDisplayLabel: "Mistral"
              dropParams: ["stop", "user", "frequency_penalty", "presence_penalty"]
         
            # OpenRouter.ai
            - name: "OpenRouter"
              apiKey: ""
              baseURL: "https://openrouter.ai/api/v1"
              models:
                default: ["openai/gpt-3.5-turbo"]
                fetch: true
              titleConvo: true
              titleModel: "gpt-3.5-turbo"
              summarize: false
              summaryModel: "gpt-3.5-turbo"
              forcePrompt: false
              modelDisplayLabel: "OpenRouter"
         
            # Perplexity
            - name: "Perplexity"
              apiKey: ""
              baseURL: "https://api.perplexity.ai/"
              models:
                default: [
                  "mistral-7b-instruct",
                  "sonar-small-chat",
                  "sonar-small-online",
                  "sonar-medium-chat",
                  "sonar-medium-online"
                  ]
                fetch: false # fetching list of models is not supported
              titleConvo: true
              titleModel: "sonar-medium-chat"
              summarize: false
              summaryModel: "sonar-medium-chat"
              forcePrompt: false
              dropParams: ["stop", "frequency_penalty"]
              modelDisplayLabel: "Perplexity"
         
            # ShuttleAI API
            - name: "ShuttleAI"
              apiKey: ""
              baseURL: "https://api.shuttleai.app/v1"
              models:
                default: [
                  "shuttle-1", "shuttle-turbo"
                  ]
                fetch: true
              titleConvo: true
              titleModel: "gemini-pro"
              summarize: false
              summaryModel: "llama-summarize"
              forcePrompt: false
              modelDisplayLabel: "ShuttleAI"
              dropParams: ["user"]
         
            # together.ai
            - name: "together.ai"
              apiKey: ""
              baseURL: "https://api.together.xyz"
              models:
                default: [
                  "zero-one-ai/Yi-34B-Chat",
                  "Austism/chronos-hermes-13b",
                  "DiscoResearch/DiscoLM-mixtral-8x7b-v2",
                  "Gryphe/MythoMax-L2-13b",
                  "lmsys/vicuna-13b-v1.5",
                  "lmsys/vicuna-7b-v1.5",
                  "lmsys/vicuna-13b-v1.5-16k",
                  "codellama/CodeLlama-13b-Instruct-hf",
                  "codellama/CodeLlama-34b-Instruct-hf",
                  "codellama/CodeLlama-70b-Instruct-hf",
                  "codellama/CodeLlama-7b-Instruct-hf",
                  "togethercomputer/llama-2-13b-chat",
                  "togethercomputer/llama-2-70b-chat",
                  "togethercomputer/llama-2-7b-chat",
                  "NousResearch/Nous-Capybara-7B-V1p9",
                  "NousResearch/Nous-Hermes-2-Mixtral-8x7B-DPO",
                  "NousResearch/Nous-Hermes-2-Mixtral-8x7B-SFT",
                  "NousResearch/Nous-Hermes-Llama2-70b",
                  "NousResearch/Nous-Hermes-llama-2-7b",
                  "NousResearch/Nous-Hermes-Llama2-13b",
                  "NousResearch/Nous-Hermes-2-Yi-34B",
                  "openchat/openchat-3.5-1210",
                  "Open-Orca/Mistral-7B-OpenOrca",
                  "togethercomputer/Qwen-7B-Chat",
                  "snorkelai/Snorkel-Mistral-PairRM-DPO",
                  "togethercomputer/alpaca-7b",
                  "togethercomputer/falcon-40b-instruct",
                  "togethercomputer/falcon-7b-instruct",
                  "togethercomputer/GPT-NeoXT-Chat-Base-20B",
                  "togethercomputer/Llama-2-7B-32K-Instruct",
                  "togethercomputer/Pythia-Chat-Base-7B-v0.16",
                  "togethercomputer/RedPajama-INCITE-Chat-3B-v1",
                  "togethercomputer/RedPajama-INCITE-7B-Chat",
                  "togethercomputer/StripedHyena-Nous-7B",
                  "Undi95/ReMM-SLERP-L2-13B",
                  "Undi95/Toppy-M-7B",
                  "WizardLM/WizardLM-13B-V1.2",
                  "garage-bAInd/Platypus2-70B-instruct",
                  "mistralai/Mistral-7B-Instruct-v0.1",
                  "mistralai/Mistral-7B-Instruct-v0.2",
                  "mistralai/Mixtral-8x7B-Instruct-v0.1",
                  "teknium/OpenHermes-2-Mistral-7B",
                  "teknium/OpenHermes-2p5-Mistral-7B",
                  "upstage/SOLAR-10.7B-Instruct-v1.0"
                  ]
                fetch: false # fetching list of models is not supported
              titleConvo: true
              titleModel: "togethercomputer/llama-2-7b-chat"
              summarize: false
              summaryModel: "togethercomputer/llama-2-7b-chat"
              forcePrompt: false
              modelDisplayLabel: "together.ai"
      '';
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

  sops = {
    secrets = {
      librechatOpenaiApiKey = {};
      librechatAnthropicApiKey = {};
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
          
          HOST=0.0.0.0
          MONGO_URI=${app2}://${app}-${app2}:27017/LibreChat
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
          ANTHROPIC_MODELS=claude-opus-4-20250514,claude-sonnet-4-20250514
          
          #============#
          # OpenAI     #
          #============#
          
          OPENAI_API_KEY=${config.sops.placeholder.librechatOpenaiApiKey}
          OPENAI_MODELS=gpt-4.1,gpt-4.1-mini,gpt-4.1-nano
          #OPENAI_MODELS=gpt-5,gpt-5-mini,gpt-5-nano
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
          ALLOW_REGISTRATION=true
          ALLOW_SOCIAL_LOGIN=false
          ALLOW_SOCIAL_REGISTRATION=false
          ALLOW_PASSWORD_RESET=false
          # ALLOW_ACCOUNT_DELETION=true # note: enabled by default if omitted/commented out
          ALLOW_UNVERIFIED_EMAIL_LOGIN=true
          SESSION_EXPIRY=1000 * 60 * 15
          REFRESH_TOKEN_EXPIRY=(1000 * 60 * 60 * 24) * 7
          JWT_SECRET=${config.sops.placeholder.librechatJwtSecret}
          JWT_REFRESH_SECRET=${config.sops.placeholder.librechatJwtRefreshSecret}
          
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
        "traefik.http.routers.${app}.rule" = "Host(`bond-ai.${configVars.domain2}`)";
        "traefik.http.routers.${app}.tls" = "true";
        "traefik.http.routers.${app}.tls.options" = "tls-13@file";
        "traefik.http.routers.${app}.middlewares" = "private-whitelist@file,secure-headers@file";
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