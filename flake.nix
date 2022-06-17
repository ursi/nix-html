{ inputs =
    { deadnix.url = "github:astro/deadnix";
      make-shell.url = "github:ursi/nix-make-shell/1";
      doc-gen.url = "git+ssh://git@git.ts.platonic.systems/mason.mackaman/nix-doc-gen.git";
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
          ({ deadnix, make-shell, doc-gen, pkgs, ... }:
             { packages.docs = doc-gen (removeAttrs (import ./. pkgs) [ "html-proofer" ]);

               devShell =
                 make-shell
                   { packages = [ deadnix ];
                     aliases.lint = ''find -name "*.nix" | xargs deadnix'';
                   };

               apps.html-proofer =
                 { type = "app";
                   program = "${pkgs.html-proofer}/bin/htmlproofer";
                 };
             }
          )
       );
}
