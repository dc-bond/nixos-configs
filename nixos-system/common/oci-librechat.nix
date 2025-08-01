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
          
          #HOST=localhost
          PORT=3080
          
          #MONGO_URI=mongodb://127.0.0.1:27017/LibreChat
          
          DOMAIN_CLIENT=https://bond-ai.opticon.dev
          DOMAIN_SERVER=https://bond-ai.opticon.dev
          
          NO_INDEX=true
          # Use the address that is at most n number of hops away from the Express application. 
          # req.socket.remoteAddress is the first hop, and the rest are looked for in the X-Forwarded-For header from right to left. 
          # A value of 0 means that the first untrusted address would be req.socket.remoteAddress, i.e. there is no reverse proxy.
          # Defaulted to 1.
          TRUST_PROXY=1
          
          #===============#
          # JSON Logging  #
          #===============#
          
          # Use when process console logs in cloud deployment like GCP/AWS
          CONSOLE_JSON=false
          
          #===============#
          # Debug Logging #
          #===============#
          
          DEBUG_LOGGING=true
          DEBUG_CONSOLE=false
          
          #=============#
          # Permissions #
          #=============#
          
          # UID=1000
          # GID=1000
          
          #===============#
          # Configuration #
          #===============#

          # Use an absolute path, a relative path, or a URL
          # CONFIG_PATH="/alternative/path/to/librechat.yaml"
          
          #===================================================#
          #                     Endpoints                     #
          #===================================================#
          
          ENDPOINTS=openAI,anthropic
          # ENDPOINTS=openAI,assistants,azureOpenAI,google,gptPlugins,anthropic
          
          PROXY=
          
          #===================================#
          # Known Endpoints - librechat.yaml  #
          #===================================#
          # https://www.librechat.ai/docs/configuration/librechat_yaml/ai_endpoints
          
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
          # ANTHROPIC_REVERSE_PROXY=
          
          #============#
          # Azure      #
          #============#
          
          # Note: these variables are DEPRECATED
          # Use the `librechat.yaml` configuration for `azureOpenAI` instead
          # You may also continue to use them if you opt out of using the `librechat.yaml` configuration
          
          # AZURE_OPENAI_DEFAULT_MODEL=gpt-3.5-turbo # Deprecated
          # AZURE_OPENAI_MODELS=gpt-3.5-turbo,gpt-4 # Deprecated
          # AZURE_USE_MODEL_AS_DEPLOYMENT_NAME=TRUE # Deprecated
          # AZURE_API_KEY= # Deprecated
          # AZURE_OPENAI_API_INSTANCE_NAME= # Deprecated
          # AZURE_OPENAI_API_DEPLOYMENT_NAME= # Deprecated
          # AZURE_OPENAI_API_VERSION= # Deprecated
          # AZURE_OPENAI_API_COMPLETIONS_DEPLOYMENT_NAME= # Deprecated
          # AZURE_OPENAI_API_EMBEDDINGS_DEPLOYMENT_NAME= # Deprecated
          # PLUGINS_USE_AZURE="true" # Deprecated
          
          #=================#
          #   AWS Bedrock   #
          #=================#
          
          # BEDROCK_AWS_DEFAULT_REGION=us-east-1 # A default region must be provided
          # BEDROCK_AWS_ACCESS_KEY_ID=someAccessKey
          # BEDROCK_AWS_SECRET_ACCESS_KEY=someSecretAccessKey
          # BEDROCK_AWS_SESSION_TOKEN=someSessionToken
          
          # Note: This example list is not meant to be exhaustive. If omitted, all known, supported model IDs will be included for you.
          # BEDROCK_AWS_MODELS=anthropic.claude-3-5-sonnet-20240620-v1:0,meta.llama3-1-8b-instruct-v1:0
          
          # See all Bedrock model IDs here: https://docs.aws.amazon.com/bedrock/latest/userguide/model-ids.html#model-ids-arns
          
          # Notes on specific models:
          # The following models are not support due to not supporting streaming:
          # ai21.j2-mid-v1
          
          # The following models are not support due to not supporting conversation history:
          # ai21.j2-ultra-v1, cohere.command-text-v14, cohere.command-light-text-v14
          
          #============#
          # Google     #
          #============#
          
          # GOOGLE_KEY=user_provided
          
          # GOOGLE_REVERSE_PROXY=
          # Some reverse proxies do not support the X-goog-api-key header, uncomment to pass the API key in Authorization header instead.
          # GOOGLE_AUTH_HEADER=true
          
          # Gemini API (AI Studio)
          # GOOGLE_MODELS=gemini-2.5-pro-preview-05-06,gemini-2.5-flash-preview-04-17,gemini-2.0-flash-001,gemini-2.0-flash-exp,gemini-2.0-flash-lite-001,gemini-1.5-pro-002,gemini-1.5-flash-002
          
          # Vertex AI
          # GOOGLE_MODELS=gemini-2.5-pro-preview-05-06,gemini-2.5-flash-preview-04-17,gemini-2.0-flash-001,gemini-2.0-flash-exp,gemini-2.0-flash-lite-001,gemini-1.5-pro-002,gemini-1.5-flash-002
          
          # GOOGLE_TITLE_MODEL=gemini-2.0-flash-lite-001
          
          # GOOGLE_LOC=us-central1
          
          # Google Safety Settings
          # NOTE: These settings apply to both Vertex AI and Gemini API (AI Studio)
          #
          # For Vertex AI:
          # To use the BLOCK_NONE setting, you need either:
          # (a) Access through an allowlist via your Google account team, or
          # (b) Switch to monthly invoiced billing: https://cloud.google.com/billing/docs/how-to/invoiced-billing
          #
          # For Gemini API (AI Studio):
          # BLOCK_NONE is available by default, no special account requirements.
          #
          # Available options: BLOCK_NONE, BLOCK_ONLY_HIGH, BLOCK_MEDIUM_AND_ABOVE, BLOCK_LOW_AND_ABOVE
          #
          # GOOGLE_SAFETY_SEXUALLY_EXPLICIT=BLOCK_ONLY_HIGH
          # GOOGLE_SAFETY_HATE_SPEECH=BLOCK_ONLY_HIGH
          # GOOGLE_SAFETY_HARASSMENT=BLOCK_ONLY_HIGH
          # GOOGLE_SAFETY_DANGEROUS_CONTENT=BLOCK_ONLY_HIGH
          # GOOGLE_SAFETY_CIVIC_INTEGRITY=BLOCK_ONLY_HIGH
          
          #============#
          # OpenAI     #
          #============#
          
          OPENAI_API_KEY=${config.sops.placeholder.librechatOpenaiApiKey}
          OPENAI_MODELS=gpt-4.1,gpt-4o-mini
          
          DEBUG_OPENAI=false
          
          # TITLE_CONVO=false
          # OPENAI_TITLE_MODEL=gpt-4o-mini
          
          # OPENAI_SUMMARIZE=true
          # OPENAI_SUMMARY_MODEL=gpt-4o-mini
          
          # OPENAI_FORCE_PROMPT=true
          
          # OPENAI_REVERSE_PROXY=
          
          # OPENAI_ORGANIZATION=
          
          #====================#
          #   Assistants API   #
          #====================#
          
          # ASSISTANTS_API_KEY=user_provided
          # ASSISTANTS_BASE_URL=
          # ASSISTANTS_MODELS=gpt-4o,gpt-4o-mini,gpt-3.5-turbo-0125,gpt-3.5-turbo-16k-0613,gpt-3.5-turbo-16k,gpt-3.5-turbo,gpt-4,gpt-4-0314,gpt-4-32k-0314,gpt-4-0613,gpt-3.5-turbo-0613,gpt-3.5-turbo-1106,gpt-4-0125-preview,gpt-4-turbo-preview,gpt-4-1106-preview
          
          #==========================#
          #   Azure Assistants API   #
          #==========================#
          
          # Note: You should map your credentials with custom variables according to your Azure OpenAI Configuration
          # The models for Azure Assistants are also determined by your Azure OpenAI configuration.
          
          # More info, including how to enable use of Assistants with Azure here:
          # https://www.librechat.ai/docs/configuration/librechat_yaml/ai_endpoints/azure#using-assistants-with-azure
          
          #============#
          # Plugins    #
          #============#
          
          # PLUGIN_MODELS=gpt-4o,gpt-4o-mini,gpt-4,gpt-4-turbo-preview,gpt-4-0125-preview,gpt-4-1106-preview,gpt-4-0613,gpt-3.5-turbo,gpt-3.5-turbo-0125,gpt-3.5-turbo-1106,gpt-3.5-turbo-0613
          
          DEBUG_PLUGINS=true
          
          CREDS_KEY=f34be427ebb29de8d88c107a71546019685ed8b241d8f2ed00c3df97ad2566f0
          CREDS_IV=e2341419ec3dd3d19b13a1a87fafcbfb
          
          # Azure AI Search
          #-----------------
          # AZURE_AI_SEARCH_SERVICE_ENDPOINT=
          # AZURE_AI_SEARCH_INDEX_NAME=
          # AZURE_AI_SEARCH_API_KEY=
          
          # AZURE_AI_SEARCH_API_VERSION=
          # AZURE_AI_SEARCH_SEARCH_OPTION_QUERY_TYPE=
          # AZURE_AI_SEARCH_SEARCH_OPTION_TOP=
          # AZURE_AI_SEARCH_SEARCH_OPTION_SELECT=
          
          # OpenAI Image Tools Customization
          #----------------
          # IMAGE_GEN_OAI_DESCRIPTION_WITH_FILES=Custom description for image generation tool when files are present
          # IMAGE_GEN_OAI_DESCRIPTION_NO_FILES=Custom description for image generation tool when no files are present
          # IMAGE_EDIT_OAI_DESCRIPTION=Custom description for image editing tool
          # IMAGE_GEN_OAI_PROMPT_DESCRIPTION=Custom prompt description for image generation tool
          # IMAGE_EDIT_OAI_PROMPT_DESCRIPTION=Custom prompt description for image editing tool
          
          # DALL·E
          #----------------
          # DALLE_API_KEY=
          # DALLE3_API_KEY=
          # DALLE2_API_KEY=
          # DALLE3_SYSTEM_PROMPT=
          # DALLE2_SYSTEM_PROMPT=
          # DALLE_REVERSE_PROXY=
          # DALLE3_BASEURL=
          # DALLE2_BASEURL=
          
          # DALL·E (via Azure OpenAI)
          # Note: requires some of the variables above to be set
          #----------------
          # DALLE3_AZURE_API_VERSION=
          # DALLE2_AZURE_API_VERSION=
          
          # Flux
          #-----------------
          FLUX_API_BASE_URL=https://api.us1.bfl.ai
          # FLUX_API_BASE_URL = 'https://api.bfl.ml';
          
          # Get your API key at https://api.us1.bfl.ai/auth/profile
          # FLUX_API_KEY=
          
          # Google
          #-----------------
          # GOOGLE_SEARCH_API_KEY=
          # GOOGLE_CSE_ID=
          
          # YOUTUBE
          #-----------------
          # YOUTUBE_API_KEY=
          
          # SerpAPI
          #-----------------
          # SERPAPI_API_KEY=
          
          # Stable Diffusion
          #-----------------
          SD_WEBUI_URL=http://host.docker.internal:7860
          
          # Tavily
          #-----------------
          # TAVILY_API_KEY=
          
          # Traversaal
          #-----------------
          # TRAVERSAAL_API_KEY=
          
          # WolframAlpha
          #-----------------
          # WOLFRAM_APP_ID=
          
          # Zapier
          #-----------------
          # ZAPIER_NLA_API_KEY=
          
          #==================================================#
          #                      Search                      #
          #==================================================#
          
          SEARCH=true
          MEILI_NO_ANALYTICS=true
          #MEILI_HOST=http://0.0.0.0:7700
          MEILI_MASTER_KEY=DrhYf7zENyR6AlUCKmnz0eYASOQdl6zxH7s7MKFSfFCt
          
          # Optional: Disable indexing, useful in a multi-node setup
          # where only one instance should perform an index sync.
          # MEILI_NO_SYNC=true
          
          #==================================================#
          #          Speech to Text & Text to Speech         #
          #==================================================#
          
          # STT_API_KEY=
          # TTS_API_KEY=
          
          #==================================================#
          #                        RAG                       #
          #==================================================#
          # More info: https://www.librechat.ai/docs/configuration/rag_api
          
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
          
          OPENAI_MODERATION=false
          # OPENAI_MODERATION_API_KEY=
          # OPENAI_MODERATION_REVERSE_PROXY=
          
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
          # Balance                #
          #========================#
          
          # CHECK_BALANCE=false
          # START_BALANCE=20000 # note: the number of tokens that will be credited after registration.
          
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
          
          # Discord
          # DISCORD_CLIENT_ID=
          # DISCORD_CLIENT_SECRET=
          # DISCORD_CALLBACK_URL=/oauth/discord/callback
          
          # Facebook
          # FACEBOOK_CLIENT_ID=
          # FACEBOOK_CLIENT_SECRET=
          # FACEBOOK_CALLBACK_URL=/oauth/facebook/callback
          
          # GitHub
          # GITHUB_CLIENT_ID=
          # GITHUB_CLIENT_SECRET=
          # GITHUB_CALLBACK_URL=/oauth/github/callback
          # GitHub Enterprise
          # GITHUB_ENTERPRISE_BASE_URL=
          # GITHUB_ENTERPRISE_USER_AGENT=
          
          # Google
          # GOOGLE_CLIENT_ID=
          # GOOGLE_CLIENT_SECRET=
          # GOOGLE_CALLBACK_URL=/oauth/google/callback
          
          # Apple
          # APPLE_CLIENT_ID=
          # APPLE_TEAM_ID=
          # APPLE_KEY_ID=
          # APPLE_PRIVATE_KEY_PATH=
          # APPLE_CALLBACK_URL=/oauth/apple/callback
          
          # OpenID
          # OPENID_CLIENT_ID=
          # OPENID_CLIENT_SECRET=
          # OPENID_ISSUER=
          # OPENID_SESSION_SECRET=
          # OPENID_SCOPE="openid profile email"
          # OPENID_CALLBACK_URL=/oauth/openid/callback
          # OPENID_REQUIRED_ROLE=
          # OPENID_REQUIRED_ROLE_TOKEN_KIND=
          # OPENID_REQUIRED_ROLE_PARAMETER_PATH=
          # Set to determine which user info property returned from OpenID Provider to store as the User's username
          # OPENID_USERNAME_CLAIM=
          # Set to determine which user info property returned from OpenID Provider to store as the User's name
          # OPENID_NAME_CLAIM=
          
          # OPENID_BUTTON_LABEL=
          # OPENID_IMAGE_URL=
          # Set to true to automatically redirect to the OpenID provider when a user visits the login page
          # This will bypass the login form completely for users, only use this if OpenID is your only authentication method
          # OPENID_AUTO_REDIRECT=false
          
          # LDAP
          # LDAP_URL=
          # LDAP_BIND_DN=
          # LDAP_BIND_CREDENTIALS=
          # LDAP_USER_SEARCH_BASE=
          # LDAP_SEARCH_FILTER="mail="
          # LDAP_CA_CERT_PATH=
          # LDAP_TLS_REJECT_UNAUTHORIZED=
          # LDAP_STARTTLS=
          # LDAP_LOGIN_USES_USERNAME=true
          # LDAP_ID=
          # LDAP_USERNAME=
          # LDAP_EMAIL=
          # LDAP_FULL_NAME=
          
          #========================#
          # Email Password Reset   #
          #========================#
          
          # EMAIL_SERVICE=
          # EMAIL_HOST=
          # EMAIL_PORT=25
          # EMAIL_ENCRYPTION=
          # EMAIL_ENCRYPTION_HOSTNAME=
          # EMAIL_ALLOW_SELFSIGNED=
          # EMAIL_USERNAME=
          # EMAIL_PASSWORD=
          # EMAIL_FROM_NAME=
          # EMAIL_FROM=noreply@librechat.ai
          
          #========================#
          # Firebase CDN           #
          #========================#
          
          # FIREBASE_API_KEY=
          # FIREBASE_AUTH_DOMAIN=
          # FIREBASE_PROJECT_ID=
          # FIREBASE_STORAGE_BUCKET=
          # FIREBASE_MESSAGING_SENDER_ID=
          # FIREBASE_APP_ID=
          
          #========================#
          # S3 AWS Bucket          #
          #========================#
          
          # AWS_ENDPOINT_URL=
          # AWS_ACCESS_KEY_ID=
          # AWS_SECRET_ACCESS_KEY=
          # AWS_REGION=
          # AWS_BUCKET_NAME=
          
          #========================#
          # Azure Blob Storage     #
          #========================#
          
          # AZURE_STORAGE_CONNECTION_STRING=
          # AZURE_STORAGE_PUBLIC_ACCESS=false
          # AZURE_CONTAINER_NAME=files
          
          #========================#
          # Shared Links           #
          #========================#
          
          ALLOW_SHARED_LINKS=true
          ALLOW_SHARED_LINKS_PUBLIC=true
          
          #==============================#
          # Static File Cache Control    #
          #==============================#
          
          # Leave commented out to use defaults: 1 day (86400 seconds) for s-maxage and 2 days (172800 seconds) for max-age
          # NODE_ENV must be set to production for these to take effect
          # STATIC_CACHE_MAX_AGE=172800
          # STATIC_CACHE_S_MAX_AGE=86400
          
          # If you have another service in front of your LibreChat doing compression, disable express based compression here
          # DISABLE_COMPRESSION=true
          
          #===================================================#
          #                        UI                         #
          #===================================================#
          
          APP_TITLE=Bond AI 
          CUSTOM_FOOTER="Bond AI"
          # HELP_AND_FAQ_URL=https://librechat.ai
          
          # SHOW_BIRTHDAY_ICON=true
          
          # Google tag manager id
          #ANALYTICS_GTM_ID=user provided google tag manager id
          
          #===============#
          # REDIS Options #
          #===============#
          
          # REDIS_URI=10.10.10.10:6379
          # USE_REDIS=true
          
          # USE_REDIS_CLUSTER=true
          # REDIS_CA=/path/to/ca.crt
          
          #==================================================#
          #                      Others                      #
          #==================================================#
          #   You should leave the following commented out   #
          
          # NODE_ENV=
          
          # E2E_USER_EMAIL=
          # E2E_USER_PASSWORD=
          
          #=====================================================#
          #                  Cache Headers                      #
          #=====================================================#
          #   Headers that control caching of the index.html    #
          #   Default configuration prevents caching to ensure  #
          #   users always get the latest version. Customize    #
          #   only if you understand caching implications.      #
          
          # INDEX_HTML_CACHE_CONTROL=no-cache, no-store, must-revalidate
          # INDEX_HTML_PRAGMA=no-cache
          # INDEX_HTML_EXPIRES=0
          
          # no-cache: Forces validation with server before using cached version
          # no-store: Prevents storing the response entirely
          # must-revalidate: Prevents using stale content when offline
          
          #=====================================================#
          #                  OpenWeather                        #
          #=====================================================#
          # OPENWEATHER_API_KEY=
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
        #"traefik.http.routers.${app}.rule" = "Host(`${app}.${configVars.domain2}`)";
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