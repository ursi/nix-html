with builtins;
pkgs:
  let
    l = p.lib; p = pkgs;
    files = import ./files.nix l;
    map-attribute = "__nix-html-map";
  in
  rec
  { basic = args: reflect (l.const args);
    inherit files;
    html = import ./html.nix l;

    html-proofer =
      p.writeScript "nix-html-htmlproofer"
        ''LC_CTYPE=C.UTF-8 ${p.html-proofer}/bin/htmlproofer "$1" --disable-external "''${@:2}"'';

    map = map: b: b // { ${map-attribute} = map; };

    make-site =
      { args =
          [ { name = "dir";
              description = "The directory that contains the source files";
            }

            { name = "spec";
              description = "An attrset whose keys denote target file extensions and whose values are attrsets themselves, whose keys denote file extensions that will be compiled to the target extension. The values of these inner attrsets are functions that describe how to compile the source files into the target files.";
            }
          ];

        notes =
          ''
          Example usage:
          ```
          nix-html.make-site
            ./website
            { html =
                nix-html.basic { args = { inherit social templates; }; }
                // { md = markdown-plugin; }
            }
          ```
          '';

        returns = "A derivation for the website";

        __functor = _: dir: spec:
          p.runCommand "site-from-${toString dir}" {}
            (l.concatStringsSep "\n"
               (builtins.map
                  ({ target, builders }:
                     let
                       change-ext = files.change-extension target;

                       paths =
                         filter
                           (path:
                              builders?${files.extension path}
                              || files.extension path == target
                           )
                           (files.recursive-list dir);


                       build-file = path:
                         let
                           make-path = path':
                             builtins.path
                               { name =
                                   l.strings.sanitizeDerivationName (baseNameOf path');

                                 path = path';
                               };
                         in
                         if files.extension path == target then
                           p.runCommand (change-ext path) {}
                             "ln -s ${make-path (dir + path)} $out"
                         else
                           builders.${files.extension path}
                             { system = dir + path;
                               site = path;
                             };

                       map' = builders.${map-attribute} or l.id;
                     in
                     l.concatMapStringsSep "\n"
                       (path:
                          let
                            build-path = change-ext path;
                            dir = "$out" + l.escapeShellArg (dirOf build-path);
                            file = "$out" + l.escapeShellArg build-path;
                          in
                          ''
                          mkdir -p ${dir}
                          ln -s ${map' (build-file path)} ${file}
                          ''
                       )
                       paths
                  )
                  (l.mapAttrsToList (target: builders: { inherit target builders; }) spec)
               )
            );
      };

    reflect = args:
      { "html.nix" = paths:
          p.writeText paths.site (import paths.system (args paths));
      };
  }
