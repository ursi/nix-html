p:
  with builtins;
  let
    l = p.lib;

    make-attributes = attributes:
      if isAttrs attributes then
        toString
          (l.mapAttrsToList
             (n: v:
               if isBool v then if v then n else ""
               else ''${n}="${toString v}"''
             )
             attributes
          )
      else
        let str = toString attributes; in
        if str == "" then ""
        else ''class="${str}"'';

    element = name: attributes: children:
      let
        children-str =
          if l.strings.isCoercibleToString children then
            toString children
          else
            abort
              ''
              "toString children" failed. Here is some info:
              name:            ${name}
              attributes:      ${toString attributes}
              typeOf children: ${typeOf children}
              '';
      in
      "<${name} ${make-attributes attributes}>${children-str}</${name}>";

    self-closing = name: attributes:
      "<${name} ${make-attributes attributes}>";
  in
  rec
  { html = import ./html.nix l;

    lib =
      let
        build-page-list = { dir, extension, plugins }:
          let
            f = path: dir:
              l.foldl'
                (acc: v:
                   if v.type == "directory" then
                     acc ++ f (path + v.name + "/") (dir + "/${v.name}")
                   else if l.hasSuffix ".${extension}" v.name then
                     acc
                     ++ [ { inherit extension path;
                            name = l.removeSuffix ".${extension}" v.name;
                          }
                        ]
                   else
                     let plugin-extensions = attrNames plugins; in
                     if any (e: l.hasSuffix ".${e}" v.name) plugin-extensions then
                       let
                         # this is so `bar` plugins don't get used on `foo.bar` files
                         # if there is a plugin for both
                         length-sorted-extensions =
                           sort
                             (a: b: stringLength a > stringLength b)
                             plugin-extensions;

                         extension =
                           l.findFirst
                             (e: l.hasSuffix ".${e}" v.name)
                             null
                             length-sorted-extensions;
                       in
                       acc
                       ++ [ { inherit extension path;
                              name = l.removeSuffix ".${extension}" v.name;
                            }
                          ]
                     else
                       acc
                )
                []
                (l.mapAttrsToList
                   (name: type: { inherit name type; })
                   (readDir dir)
                );
          in
            f "/" dir;
      in
      { build-pages =
          { dir
          , args ? { h = html; }
          , extension ? "html.nix"
          , map ? l.id
          , plugins ? {}
          }:
          let html-map = map; in
          # let inherit (builtins) map; in
          if args?validate-link then
            abort "The 'validate-link' argument will be overridden"
          else
            let
              page-list = build-page-list { inherit dir extension plugins; };

              validate-link = file-path: path:
                let
                  valid-absolute-path =
                    any (a: a.path == path || path == a.path + a.name + ".html") page-list;

                  valid-relative-path =
                    # improve this so it can handle `.` and `..`
                    any
                      (a:
                         file-path + path == a.path
                         || file-path + path == a.path + a.name + ".html"
                      )
                      page-list;
                in
                assert valid-absolute-path || valid-relative-path;
                path;

              html-file = { name, path, ... }@a:
                let full-path = dir + (path + "${name}.${a.extension}"); in
                (p.writeText "${path + name}.html"
                   (if a.extension == extension then
                      import full-path (args // { validate-link = validate-link path; })
                    else
                      plugins.${a.extension} full-path
                   )
                )
                .overrideAttrs
                  (_:
                     { passthru =
                         { file-name = "${name}.html";
                           inherit (a) extension;
                           inherit path;
                         };
                     }
                  );
            in
            l.concatMapStringsSep "\n"
              ({ extension, name, path }@v:
                 ''
                 mkdir -p .${path}
                 ln -s ${html-map (html-file v)} .${path + name}.html
                 ''
              )
              page-list;

        escape = replaceStrings [ "<" ">" "&" ] [ "&lt;" "&gt;" "&amp;" ];

        link-validator = { dir , extension ? "html.nix" }: path:
              let
                valid-absolute-path =
                  any
                    (a: a.path == path || path == a.path + a.name + ".html")
                    (build-page-list { inherit dir extension plugins; });

              in
              assert valid-absolute-path;
              path;
      };
  }
