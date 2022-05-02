with builtins;
l:
  rec
  { change-extension =
      { args =
          [ { name = "new-ext";
              description = "the new extension";
            }

            { name = "path";
              description = "A string of a path to a file";
            }
          ];

        returns = "`path` with its extension changed to `new-ext`";

        examples =
          [ ''change-extension "html" "/home/me/file.txt" == "/home/me/file.html"'' ];

        __functor = _: new-ext: path:
          let ext = extension path; in
          if ext == "" then path
          else l.removeSuffix ext path + new-ext;
      };

    extension =
      { args = [ { name = "path"; description = "A string of a path to a file"; } ];
        returns = "`path`'s extension";

        examples =
          [ ''extension "/home/me/file.txt" == "txt"''
            ''extension "file.abc.txt" == "abc.txt"''
            ''extension ".abc.txt" == "abc.txt"''
            ''extension ".txt" == "txt"''
            ''extension "txt" == ""''
          ];

        __functor = _:
          path:
            let match' = match ''[^.]*\.(.+)'' (baseNameOf path); in
            if isNull match' then "" else head match';
      };

    name = path: l.removeSuffix ".${extension path}" (baseNameOf path);

    recursive-list =
      { args =
          [ { name = "dir";
              description = "A directory";
            }
          ];

        returns = "A list of paths, relative to `dir`, for every file contained in `dir`, recursively";

        __functor = _: dir:
          let
            f = path: dir:
              foldl'
                (acc: v:
                   if v.type == "directory" then
                     acc ++ f (path + v.name + "/") (dir + "/${v.name}")
                   else
                     acc ++ [ (path + v.name) ]
                )
                []
                (l.mapAttrsToList
                   (name: type: { inherit name type; })
                   (readDir dir)
                );
          in
          f "/" dir;
      };
  }
