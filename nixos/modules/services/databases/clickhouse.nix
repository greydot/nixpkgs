{ config, lib, pkgs, ... }:
let
  cfg = config.services.clickhouse;
  createProfile = n: p: ''
  <${n}>
    ${if p.max_threads != null
       then "<max_threads>" + toString p.max_threads + "</max_threads>"
       else ""}

    ${if p.max_memory_usage != null
       then "<max_memory_usage>" + toString p.max_memory_usage + "</max_memory_usage>"
       else ""}

    <use_uncompressed_cache>${if p.use_uncompressed_cache then "1" else "0"}</use_uncompressed_cache>
    <load_balancing>${p.load_balancing}</load_balancing>
    <readonly>${if p.readonly then "1" else "0"}</readonly>

    ${p.extraConfig}
  </${n}>
  '';
  createConfig = cfg: pkgs.writeText "config.xml" ''
<?xml version="1.0"?>
<yandex>
    <logger>
        <level>trace</level>
        <console>1</console>
        <size>1000M</size>
        <count>10</count>
        <!-- <console>1</console> --> <!-- Default behavior is autodetection (log to console if not daemon mode and is tty) -->
    </logger>
    <display_name>${cfg.display_name}</display_name>
    <http_port>${toString cfg.http_port}</http_port>
    <tcp_port>${toString cfg.tcp_port}</tcp_port>

    <interserver_http_port>${toString cfg.interserver_http_port}</interserver_http_port>

    ${if cfg.interserver_http_host != null
      then "<interserver_http_host>" + cfg.interserver_http_host + "</interserver_http_host>"
      else ""}

    ${lib.strings.concatMapStrings (a: "<listen>"+a+"</listen>\n") cfg.host}

    <listen_reuse_port>${if cfg.reuse_port then "1" else "0"}</listen_reuse_port>
    <max_connections>${toString cfg.max_connections}</max_connections>
    <keep_alive_timeout>${toString cfg.keep_alive_timeout}</keep_alive_timeout>
    <max_concurrent_queries>${toString cfg.max_concurrent_queries}</max_concurrent_queries>

    <uncompressed_cache_size>8589934592</uncompressed_cache_size>

    <mark_cache_size>5368709120</mark_cache_size>

    <!-- Path to data directory, with trailing slash. -->
    <path>/var/lib/clickhouse/</path>

    <!-- Path to temporary data for processing hard queries. -->
    <tmp_path>/var/lib/clickhouse/tmp/</tmp_path>

    <!-- Directory with user provided files that are accessible by 'file' table function. -->
    <user_files_path>/var/lib/clickhouse/user_files/</user_files_path>

    <!-- Path to configuration file with users, access rights, profiles of settings, quotas. -->
    <users_config>/etc/clickhouse-server/users.xml</users_config>

    <!-- Default profile of settings. -->
    <default_profile>default</default_profile>

    <!-- System profile of settings. This settings are used by internal processes (Buffer storage, Distibuted DDL worker and so on). -->
    <!-- <system_profile>default</system_profile> -->

    <default_database>${cfg.default_database}</default_database>


    <!-- Reloading interval for embedded dictionaries, in seconds. Default: 3600. -->
    <builtin_dictionaries_reload_interval>3600</builtin_dictionaries_reload_interval>


    <!-- Maximum session timeout, in seconds. Default: 3600. -->
    <max_session_timeout>3600</max_session_timeout>

    <!-- Default session timeout, in seconds. Default: 60. -->
    <default_session_timeout>60</default_session_timeout>

    <format_schema_path>/var/lib/clickhouse/format_schemas/</format_schema_path>

    ${cfg.extraConfig}
</yandex>
'';
in
with lib;
{

  ###### interface

  options = {

    services.clickhouse = {

      enable = mkOption {
        default = false;
        description = "Whether to enable ClickHouse database server.";
      };

      package = mkOption {
        default = pkgs.clickhouse;
        defaultText = "pkgs.clickhouse";
        type = types.package;

        description = ''
          Which clickhouse derivation to use.
        '';
      };

      display_name = mkOption {
        type = types.str;
        default = "";
        description = ''
          The name that will be shown in the client.
        '';
      };

      host = mkOption {
        type = types.listOf (types.str);
        default = ["127.0.0.1" "::1"];
        description = ''
          Host address for Clickhouse to listen on.
        '';
      };

      tcp_port = mkOption {
        type = types.ints.between 1 65534;
        default = 9000;
        description = ''
          Port for TCP interface.
        '';
      };

      http_port = mkOption {
        type = types.ints.between 1 65534;
        default = 8123;
        description = ''
          Port for HTTP interface.
        '';
      };

      reuse_port = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Allow listen on same address:port
        '';
      };

      interserver_http_host = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          Hostname that is used by other replicas to request this server.
        '';
      };

      interserver_http_port = mkOption {
        type = types.ints.between 1 65534;
        default = 9009;
        description = ''
          Port for communication between replicas. Used for data exchange.
        '';
      };

      max_connections = mkOption {
        type = types.int;
        default = 4096;
        description = ''
          Maximum number of concurrent connections.
        '';
      };

      keep_alive_timeout = mkOption {
        type = types.int;
        default = 3;
        description = ''
          Connection timeout.
        '';
      };

      max_concurrent_queries = mkOption {
        type = types.int;
        default = 100;
        description = ''
          Maximum number of concurrent queries.
        '';
      };

      default_database = mkOption {
        type = types.str;
        default = "default";
        description = ''
          Default database to use.
        '';
      };

      profiles = mkOption {
        default = {
          default = {
            max_memory_usage = 10000000000;
            readonly = false;
          };
        };
        description = ''
          List of user profiles.
        '';
        type = with types; attrsOf (submodule {
          options = {

            max_threads = mkOptions {
              type = types.nullOr types.int;
              default = null;
              description = ''
                Maximum number of threads for processing a single query.
              '';
            };

            max_memory_usage = mkOption {
              type = types.nullOr types.int;
              default = null;
              description = ''
                Maximum memory usage for processing a single query, in bytes.
              '';
            };

            use_uncompressed_cache = mkOption {
              type = types.bool;
              default = false;
              description = ''
                 Use cache of uncompressed blocks of data. Meaningful only for processing many of very short queries.
              '';
            };

            load_balancing = mkOption {
              type = types.enum [ "random" "nearest_hostname" "in_order" "first_or_random" ];
              default = "random";
              description = ''
                How to choose between replicas during distributed query processing.
              '';
            };

            readonly = mkOption {
              type = types.bool;
              default = false;
              description = ''
                Allow only readonly queries for the profile.
              '';
            };

            extraConfig = mkOption {
              type = types.lines;
              default = "";
              description = ''
                Extra configuration for a profile.
              '';
            };

          };
        });
      };

      users = mkOption {
        default = { };
        description = ''
          List of user accounts.
        '';
        type = with types; attrsOf (submodule {
          password = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = ''
              Password of this user.

              NOTE: this is mutually exclusive with password_sha256.
            '';
          };

          password_sha256 = mkOption {
            type = types.nullOr types.str;
            default = null;

          };
        });
      };

      extraConfig = mkOption {
        type = types.lines;
        default = '''';
        description = ''
          Extra configuration put at the end of config.xml.
          Note that it must not include &lt;yandex&gt; tags.
        '';
      };

    };

  };


  ###### implementation

  config = mkIf cfg.enable {

    users.users.clickhouse = {
      name = "clickhouse";
      uid = config.ids.uids.clickhouse;
      group = "clickhouse";
      description = "ClickHouse server user";
    };

    users.groups.clickhouse.gid = config.ids.gids.clickhouse;

    systemd.services.clickhouse = {
      description = "ClickHouse server";

      wantedBy = [ "multi-user.target" ];

      after = [ "network.target" ];

      serviceConfig = {
        User = "clickhouse";
        Group = "clickhouse";
        ConfigurationDirectory = "clickhouse-server";
        StateDirectory = "clickhouse";
        LogsDirectory = "clickhouse";
        ExecStart = "${pkgs.clickhouse}/bin/clickhouse-server --config-file=${createConfig cfg}";
      };
    };

    environment.etc = {
      "clickhouse-server/users.xml" = {
        source = "${pkgs.clickhouse}/etc/clickhouse-server/users.xml";
      };
    };

    environment.systemPackages = [ cfg.package ];

    # startup requires a `/etc/localtime` which only if exists if `time.timeZone != null`
    time.timeZone = mkDefault "UTC";

  };

}
