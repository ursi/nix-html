with builtins;
p:
  rec
  { compose = acc: map-or-path:
      if isFunction map-or-path then
        compose (path: map-or-path (acc path))
      else
        acc map-or-path;

    str = map: path:
      p.writeText "${path}-mapped" (map (readFile path));
  }
