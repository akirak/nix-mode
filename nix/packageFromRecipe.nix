{
  recipeFile,
  parseRecipe,
  expandPackageFiles,
  src,
  filterAttrs,
  mapAttrsToList
}:
let
  recipeAttrs = parseRecipe (builtins.readFile recipeFile);
  isElisp = file: builtins.match ".+\.el" file != null;
  mainFileRegex = "(.*/)?" + recipeAttrs.pname + "\.el";
  isMainFile = file: builtins.match mainFileRegex (builtins.baseNameOf file) != null;
  packageFiles = 
    builtins.listToAttrs
      (map (file: {
        name = builtins.baseNameOf file;
        value = file;
      })
      (builtins.filter (file: builtins.match "(.*/)?flycheck_.+\.el" file == null)
        (expandPackageFiles src recipeAttrs.files)));
  sourceFiles = filterAttrs (n: _: isElisp n) packageFiles;
  sourceFilesAsList =
    mapAttrsToList (_: v: v) sourceFiles;
  mainFile =
    if builtins.length sourceFilesAsList == 1
    then builtins.head sourceFilesAsList
    else builtins.head (builtins.filter isMainFile sourceFilesAsList);
in
{
  inherit (recipeAttrs) pname;
  inherit packageFiles sourceFiles mainFile src;
}
