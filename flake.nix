{
  description = "An emacs major mode for editing Nix expressions";

  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.flake-compat = {
    url = "github:edolstra/flake-compat";
    flake = false;
  };
  inputs.emacs-overlay.url = "github:nix-community/emacs-overlay";
  inputs.gitignore = {
    url = "github:hercules-ci/gitignore.nix";
    flake = false;
  };
  inputs.pre-commit-hooks-nix = {
    url = "github:cachix/pre-commit-hooks.nix";
    flake = false;
  };
  inputs.melpa = {
    url = "github:melpa/melpa";
    flake = false;
  };
  inputs.fromElisp = {
    url = "github:talyz/fromElisp";
    flake = false;
  };
  inputs.nix-elisp-helpers = {
    url = "github:akirak/nix-elisp-helpers";
    flake = false;
  };

  outputs = { self, nixpkgs, flake-utils, flake-compat, ... }@inputs:
    (flake-utils.lib.eachSystem [
      "x86_64-linux"
      "i686-linux"
      "x86_64-darwin"
      "aarch64-linux"
    ] (system:
      let
        pkgs = (import nixpkgs {
          inherit system;
        }).extend inputs.emacs-overlay.overlay;

        nix-elisp-helpers = import inputs.nix-elisp-helpers { inherit pkgs; };

        gitignoreSource = (import inputs.gitignore {
          inherit (pkgs) lib;
        }).gitignoreSource;

        # src = gitignoreSource self;
        src = gitignoreSource ./.;

        packageFromRecipe = recipeFile:
          import ./nix/packageFromRecipe.nix {
            inherit src;
            inherit (nix-elisp-helpers) parseRecipe expandPackageFiles;
            inherit recipeFile;
            inherit (pkgs.lib) filterAttrs mapAttrsToList;
          };

        recipeDir = src + "/.recipes";

        recipeFiles =
              builtins.attrNames
              (pkgs.lib.filterAttrs (_n: type: type == "regular")
                (builtins.readDir recipeDir));

        packagesFromRecipes =
            builtins.listToAttrs
              (map (file: rec {
                name = value.pname;
                value = packageFromRecipe (recipeDir + "/${file}");
              }) recipeFiles);
      in
        rec {
          packages.packageInfo = pkgs.writeTextFile {
            name = "packages-json";
            text = builtins.toJSON packagesFromRecipes;
          };
          defaultPackage = packages.packageInfo;
            
          # defaultPackage = packages.info;

# checks =
        }
    ))
  // { inherit flake-compat; };
    
    # let
    #   systems = ;
    #   forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system);
    # in
      
    #   {
    #   packages = forAllSystems (system: with (import nixpkgs { inherit system; }); {
    #     nix-mode = let
    #       emacs = emacsWithPackages (epkgs: with epkgs; [
    #         org-plus-contrib
    #         company
    #         mmm-mode
    #       ]);
    #     in stdenvNoCC.mkDerivation {
    #       name = "nix-mode-1.4.5";
    #       src = self;
    #       nativeBuildInputs = [ emacs texinfo git ];
    #       makeFlags = [ "PREFIX=$(out)" ];
    #       shellHook = ''
    #       echo Run make run to get vanilla emacs with nix-mode loaded.
    #     '';
    #       doCheck = true;
    #     };
    #   });

    #   defaultPackage = forAllSystems (system: self.packages.${system}.nix-mode);

    #   # checks are run in ‘make check’ right now we should probably move
    #   # these to its own derivation
    #   checks = forAllSystems (system: {
    #     inherit (self.packages.${system}) nix-mode;
    #   });
    # };

}
