{ rustPlatform, lib }:

rustPlatform.buildRustPackage {
  pname = "tidal-vis";
  version = "0.1.0";
  src = ./.;
  cargoHash = lib.fakeHash;

  meta = {
    description = "Per-orbit TidalCycles visualizer for the terminal";
    license = lib.licenses.mit;
    mainProgram = "tidal-vis";
  };
}
