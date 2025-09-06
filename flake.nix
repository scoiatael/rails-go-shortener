{
  description = "A demo of sqlite-web and multiple postgres services";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    systems.url = "github:nix-systems/default";
    process-compose-flake.url = "github:Platonic-Systems/process-compose-flake";
    services-flake.url = "github:juspay/services-flake";
    just-flake.url = "github:WootingKb/just-flake";
  };
  outputs = inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = import inputs.systems;
      imports = [
        inputs.process-compose-flake.flakeModule
        inputs.just-flake.flakeModule
      ];
      perSystem = { self', pkgs, config, lib, ... }: {
        process-compose."dev" = { config, ... }:
          let
            dbName = "shortener";
            socketDir = "/tmp/rails-go-shortener/";
          in {
            imports = [ inputs.services-flake.processComposeModules.default ];

            services.postgres."pg" = {
              enable = true;
              inherit socketDir;
            };

            services.redis."redis".enable = true;
            services.nats-server."nats".enable = true;

            settings.processes.pgweb = let pgcfg = config.services.postgres.pg1;
            in {
              environment.PGWEB_DATABASE_URL =
                pgcfg.connectionURI { inherit dbName; };
              command = pkgs.pgweb;
              depends_on."pg1".condition = "process_healthy";
            };
            settings.processes.test = {
              command = pkgs.writeShellApplication {
                name = "pg1-test";
                runtimeInputs = [ config.services.postgres.pg1.package ];
                text = ''
                  echo 'SELECT version();' | psql -h 127.0.0.1 ${dbName}
                '';
              };
              depends_on."pg1".condition = "process_healthy";
            };
          };

        devShells.default =
          let pgcfg = config.process-compose.dev.services.postgres.pg;
          in pkgs.mkShell {
            inputsFrom = [ config.just-flake.outputs.devShell ];
            packages = with pkgs; [
              (ruby.withPackages (p: [ p.rails ]))
              # Ruby needs these:
              libyaml
              libpq

              pkgs.go

              nodePackages.prettier

              nodejs_24
              yarn

              pgcfg.package
              pkgs.natscli
            ];
            # DATABASE_URL = pgcfg.connectionURI {
            #   dbName = "wooting_v2_w60he_pre_order_game_development";
            # };
          };
      };
    };
}
