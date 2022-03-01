pkgs:
  with builtins;
  let
    l = p.lib; p = pkgs;
    files = import ./files.nix l;
  in
  rec
  { inherit files;
    html = import ./html.nix l;
    builders = import ./builders.nix p;

    make-path-validator = { relative-path, dir, spec }:
      let
        file-list = filter (a: spec?${files.extension a}) (files.recursive-list dir);
        dir-of = p: let d = dirOf p; in if d == "/" then d else d + "/";
        to-html = files.change-extension "html";
      in
      path-in-html:
        let
          make-tests = modify: path:
            elem
              (modify path-in-html)
              [ (dir-of path)
                (to-html path)
                (l.removeSuffix ".html" (to-html path))
              ];

          valid-absolute-path = any (make-tests l.id) file-list;

          valid-relative-path =
            # improve this so it can handle `.` and `..`
            any (make-tests (p: dir-of relative-path + p)) file-list;
        in
        assert valid-absolute-path || valid-relative-path;
        path-in-html;

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
               if files.extension path == target then
                 p.writeText
                   (change-ext path)
                   (readFile (dir + path))
               else
                 builders.${files.extension path}
                   { absolute-path = dir + path;
                     relative-path = path;
                   };

             # will implement later
             map' = l.id;
           in
           target-dir:
             acc target-dir
             + l.concatMapStringsSep "\n"
                 (path:
                    let build-path = change-ext path; in
                    ''
                    mkdir -p ${target-dir + dirOf build-path}
                    ln -s ${map' (build-file path)} ${target-dir + build-path}
                    ''
                 )
                 paths
        )
        (l.const "")
        (l.mapAttrsToList l.nameValuePair spec);
  }
