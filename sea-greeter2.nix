{
  lib,
  stdenv,
  fetchFromGitHub,
  meson,
  ninja,
  pkg-config,
  wrapGAppsHook3,
  gtk3,
  webkitgtk_4_1,
  lightdm,
  glib,
  libyaml,
  typescript,
  theme ? null,
  backgrounds ? null,
  enableHWAcceleration ? true, # Default to true, disabled via wrapper if false
}:

stdenv.mkDerivation rec {
  pname = "sea-greeter";
  version = "unstable-2024-02-03";

  src = fetchFromGitHub {
    owner = "JezerM";
    repo = "sea-greeter";
    rev = "ffd2f3c52601127a46d478cd2cd4a9e03719c73f";
    hash = "sha256-jAk1DTftPtG9mj0NmDX0zhzRZkHAFpdAklRgBE3Orrc=";
    fetchSubmodules = true;
  };

  nativeBuildInputs = [
    meson
    ninja
    pkg-config
    typescript
    wrapGAppsHook3
  ];

  buildInputs = [
    gtk3
    webkitgtk_4_1
    lightdm
    glib
    libyaml
  ];

  postPatch = ''
    substituteInPlace src/theme.c \
      --replace '/usr/share/web-greeter/themes/' "${placeholder "out"}/share/web-greeter/themes/"

    substituteInPlace src/settings.c \
      --replace '/etc/lightdm/web-greeter.yml' "${placeholder "out"}/etc/lightdm/web-greeter.yml" \
      --replace '/usr/share/web-greeter/themes/' "${placeholder "out"}/share/web-greeter/themes/"
    
    substituteInPlace data/web-greeter.yml \
      --replace '/usr/share/' "${placeholder "out"}/share/"

    for file in $(find . -name "meson.build"); do
      substituteInPlace "$file" \
        --replace "/usr/share" "${placeholder "out"}/share" \
        --replace "/usr/lib"   "${placeholder "out"}/lib" \
        --replace "/etc"       "${placeholder "out"}/etc"
    done

    substituteInPlace src/meson.build \
      --replace "webkit2gtk-4.0" "webkit2gtk-4.1" \
      --replace "webkit2gtk-web-extension-4.0" "webkit2gtk-web-extension-4.1"
      
    sed -i 's/libsoup-2.4/libsoup-3.0/g' src/meson.build
  '';

  mesonFlags = [
    "--sysconfdir=${placeholder "out"}/etc"
    "--datadir=${placeholder "out"}/share"
  ];

  preConfigure = lib.optionalString (theme != null) ''
    substituteInPlace data/web-greeter.yml \
      --replace 'theme: gruvbox' "theme: ${theme.pname}"
  '';

  postInstall = ''
    substituteInPlace $out/share/xgreeters/sea-greeter.desktop \
      --replace "Exec=sea-greeter" "Exec=$out/bin/sea-greeter"

    ln -s $out/share/xgreeters/sea-greeter.desktop $out/sea-greeter.desktop

    ${lib.optionalString (theme != null) ''
      mkdir -p $out/share/web-greeter/themes
      ln -s ${theme} $out/share/web-greeter/themes/${theme.pname}
    ''}
  '';

  preFixup = lib.optionalString (!enableHWAcceleration) ''
    gappsWrapperArgs+=(
      --set WEBKIT_DISABLE_DMABUF_RENDERER 1
    )
  '';

  meta = with lib; {
    description = "Another LightDM greeter made with WebKitGTK2";
    homepage = "https://github.com/JezerM/sea-greeter";
    license = licenses.gpl3;
    platforms = platforms.linux;
    maintainers = [ ];
  };
}
