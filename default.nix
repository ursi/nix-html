with builtins;
pkgs:
  let
    l = p.lib; p = pkgs;
    files = import ./files.nix l;
  in
  rec
  { const-builder =
      { args =
          [ { name = "args";
              # description = "An attrset that will be passed into all the `*.html.nix` files";
              description = "anything";
            }
          ];

        notes =
          ''
          Example usage:
          ```
          nix-html.make-site
            ./website
            { html."html.nix" = nix-html.const-builder { inherit social templates; }; }
          ```
          '';

        # returns = "A builder for `*.html.nix` files";
        returns = "A builder that passes `args` into each file and writes the result to a derivation";

        __functor = args: reflect (l.const args);
      };

    inherit files;
    html = import ./html.nix l;

    html-proofer =
      p.writeScript "nix-html-htmlproofer"
        ''LC_CTYPE=C.UTF-8 ${p.html-proofer}/bin/htmlproofer "$1" --disable-external "''${@:2}"'';

    map =
      { args =
          [ { name = "map";
              description = "A function that takes a path as an argument, and returns a path";
            }

            { name = "builders";
              description = "An attribute set of builders for a particular target.";
            }
          ];

        notes =
          ''
          Example usage:
          ```
          nix-html.make-site
            ./website
            { html =
                nix-html.map
                  minify-html
                  { "html.nix" = nix-html.const-builder { inherit social templates; }
                     md = markdown-plugin;
                  };
            }
          ```
          '';

        returns = "A attrset of builders that is the same as `builders`, but with their outputs run through `map`.";

        __functor = _: map: l.mapAttrs (_: v: paths: map (v paths));
      };

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
                nix-html.map
                  minify-html
                  { "html.nix" = nix-html.const-builder { inherit social templates; }
                     md = markdown-plugin;
                  };
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
                          ln -s ${build-file path} ${file}
                          ''
                       )
                       paths
                  )
                  (l.mapAttrsToList (target: builders: { inherit target builders; }) spec)
               )
            );
      };

    builder =
      { args =
          [ { name = "args";
              description = "A function that takes a `paths` argument and returns anything";
            }
          ];

        notes =
          ''
          `paths` is an attrset with the following attributes
            - `system`: the absolute path to the file on you system
            - `site`: the path to the file on the site

          Example usage:
          ```
          nix-html.make-site
            ./website
            { html."html.nix" =
                nix-html.builder
                  (paths:
                     { inherit social templates;
                       inherit (paths) site;
                     }
                  );
            }
          ```
          '';

        returns = "A builder that passes `args paths` into each file and writes the result to a derivation";

        __functor = _: args: paths:
          p.writeText paths.site (import paths.system (args paths));
      };
  }

  # l.pipe
  #   { inherit social templates;
  #     inherit (paths) site;
  #   }
  #   [ l.const nix-html.builder ]


  # nix-html.builder
  #   (_: { inherit social templates;
  #         inherit (paths) site;
  #       }
  #   )

  # nix-html.builder
  #   (_:
  #      { inherit social templates;
  #        inherit (paths) site;
  #      }
  #   )

  # nix-html.builder (_:
  #   { inherit social templates;
  #     inherit (paths) site;
  #   })
