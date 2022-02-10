{ inputs =
    { deadnix.url = "github:astro/deadnix";
      make-shell.url = "github:ursi/nix-make-shell/1";
      nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
      utils.url = "github:ursi/flake-utils/8";
    };

  outputs = { nixpkgs, utils, ... }@inputs:
    { __functor = _: { pkgs }: import ./. pkgs; }
    // (utils.apply-systems { inherit inputs; }
          ({ deadnix, make-shell, ...}:
             { devShell =
                 make-shell
                   { packages = [ deadnix ];
                     aliases.lint = ''find -name "*.nix" | xargs deadnix'';
                   };

             }
          )
       );
}
