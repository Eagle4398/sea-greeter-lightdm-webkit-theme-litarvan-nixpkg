{ lib, fetchFromGitHub, buildNpmPackage }:

buildNpmPackage rec {
  pname = "lightdm-webkit-theme-litarvan";
  version = "unstable-2023-03-10";

  src = fetchFromGitHub {
    owner = "Litarvan";
    repo = "lightdm-webkit-theme-litarvan";
    rev = "0062bb174d3931eade25c83e4e2947027c9a063a";
    hash = "sha256-SK6OTWGKtz6rFyUU6KE6zIjdhF5AhKdIKDk32hPKFRs=";
  };

  npmDepsHash = "sha256-+gaS/8Dr35lMKqfH9NKlCgJTpaqA0AlWS3Cx5TNrWyk=";

  installPhase = ''
    runHook preInstall
    install -d $out
    cp -r dist/* $out
    runHook postInstall
  '';

  meta = with lib; {
    description = "Litarvan's LightDM HTML Theme";
    homepage = "https://github.com/Litarvan/lightdm-webkit-theme-litarvan";
    license = licenses.bsd3;
    platforms = platforms.linux;
    maintainers = [ Litarvan ];
  };
}
