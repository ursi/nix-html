with builtins;
p:
  let l = p.lib; in
  rec
  { basic = args: reflect (l.const args);

    reflect = args:
      { "html.nix" = ps:
          p.writeText ps.relative-path (import ps.absolute-path (args ps));
      };
  }
