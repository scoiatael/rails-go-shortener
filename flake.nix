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
      perSystem = let
        dbName = "rails_go_shortener_development";
        socketDir = "/tmp/rails-go-shortener/";
      in { self', pkgs, config, lib, ... }: {
        process-compose."dev" = { config, ... }: {
          imports = [ inputs.services-flake.processComposeModules.default ];

          cli = {
            # Global options for `process-compose`
            options = { no-server = true; };
          };

          services.postgres."pg" = {
            enable = true;
            inherit socketDir;
          };

          services.redis."redis".enable = true;
          services.nats-server."nats".enable = true;
          services.nats-server."nats".settings.host =
            "127.0.0.1"; # In dev, listen only on localhost

          settings.processes = {
            pgtest = {
              command = pkgs.writeShellApplication {
                name = "pg-test";
                runtimeInputs = [ config.services.postgres.pg.package ];
                text = ''
                  echo 'SELECT version();' | psql -h 127.0.0.1 ${dbName}
                '';
              };
              depends_on."pg".condition = "process_healthy";
              depends_on."setup".condition = "process_completed_successfully";
            };

            pgweb = let pgcfg = config.services.postgres.pg;
            in {
              environment.PGWEB_DATABASE_URL =
                pgcfg.connectionURI { inherit dbName; };
              command = "${lib.getExe pkgs.pgweb} --skip-open";
              depends_on."pg".condition = "process_healthy";
              depends_on."setup".condition = "process_completed_successfully";
            };

            setup = {
              command = ''
                bin/setup
              '';
              depends_on.pg.condition = "process_healthy";
              availability.restart = "on_failure";
            };
          } // (lib.lists.foldl' (acc:
            { name, process }:
            acc // (let
            in {
              "${name}" = {
                depends_on = {
                  setup = { condition = "process_completed_successfully"; };
                };
                availability.restart = "on_failure";
              } // process;
            })) { } [{
              name = "rails-server";
              process = { command = "bin/rails server"; };
            }]);
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
            DATABASE_HOST = socketDir;
          };
      };
    };
}
