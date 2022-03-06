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

    make-builder = dir: spec:
      foldl'
        (acc: a:
           let
             target = a.name;
             builders = a.value;
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
                     { name = l.strings.sanitizeDerivationName (baseNameOf path');
                       path = path';
                     };
               in
               if files.extension path == target then
                 p.runCommand (change-ext path) {} "ln -s ${make-path (dir + path)} $out"
               else
                 builders.${files.extension path}
                   { absolute-path = dir + path;
                     relative-path = path;
                   };

             map' = builders.${map-attribute} or l.id;
           in
           target-dir:
             acc target-dir
             + l.concatMapStringsSep "\n"
                 (path:
                    let
                      build-path = change-ext path;
                      dir = target-dir + l.escapeShellArg (dirOf build-path);
                      file = target-dir + l.escapeShellArg build-path;
                    in
                    ''
                    mkdir -p ${dir}
                    ln -s ${map' (build-file path)} ${file}
                    ''
                 )
                 paths
        )
        (l.const "")
        (l.mapAttrsToList l.nameValuePair spec);

    reflect = args:
      { "html.nix" = ps:
          p.writeText ps.relative-path (import ps.absolute-path (args ps));
      };
  }
