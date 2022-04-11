with builtins;
l:
  rec
  { change-extension = new-ext: path:
      let ext = extension path; in
      if ext == "" then path
      else l.removeSuffix ext path + new-ext;

    extension = path:
      let match' = match ''[^.]*\.(.+)'' (baseNameOf path); in
      if isNull match' then "" else head match';

    name = path: l.removeSuffix ".${extension path}" (baseNameOf path);

    recursive-list = dir:
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
  }
