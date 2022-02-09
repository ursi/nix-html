{ outputs = { ... }: { __functor = _: { pkgs }: import ./. pkgs; }; }
