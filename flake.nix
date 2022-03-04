{ inputs =
    { deadnix.url = "github:astro/deadnix";
      make-shell.url = "github:ursi/nix-make-shell/1";
      nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
      utils.url = "github:ursi/flake-utils/8";
    };

  outputs = { nixpkgs, utils, ... }@inputs:
    nixpkgs.lib.setFunctionArgs
      (args:
         if !args?pkgs && !args?system then
           abort "One of [pkgs|system] must be defined"
         else
           import ./.
              (if args?system then
                 nixpkgs.legacyPackages.${args.system}
               else
                 args.pkgs
              )
      )
      { pkgs = true; system = false; }
    // (utils.apply-systems { inherit inputs; }
          ({ deadnix, make-shell, ... }:
             { devShell =
                 make-shell
                   { packages = [ deadnix ];
                     aliases.lint = ''find -name "*.nix" | xargs deadnix'';
                   };

             }
          )
       );
}
