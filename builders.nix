with builtins;
{ map-attribute, p }:
  let l = p.lib; in
  rec
  { basic = args: reflect (l.const args);
    map = map: b: b // { ${map-attribute} = map; };

    reflect = args:
      { "html.nix" = ps:
          p.writeText ps.relative-path (import ps.absolute-path (args ps));
      };
  }
