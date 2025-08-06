{ lib, stdenv, fetchFromGitHub, meson, ninja, pkg-config, gtk3, webkitgtk, lightdm, glib, libyaml, typescript, fetchurl }:

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

themeSrc = fetchurl {
    url = "https://github.com/Litarvan/lightdm-webkit-theme-litarvan/releases/download/v3.2.0/lightdm-webkit-theme-litarvan-3.2.0.tar.gz";
    hash = "sha256-lt0ujW5TbxtXHfbNBUtPlMVUvibxqSPvPHmMgLEyCwc=";
  };

  nativeBuildInputs = [
    meson
    ninja
    pkg-config
    typescript  
  ];

  buildInputs = [
    gtk3
    webkitgtk
    lightdm
    glib
    libyaml
  ];

  configurePhase = ''
    runHook preConfigure

    substituteInPlace src/theme.c \
    --replace '/usr/share/web-greeter/themes/' \
              "$out/usr/share/web-greeter/themes/"
    substituteInPlace src/settings.c \
    --replace '/etc/lightdm/web-greeter.yml' \
              "$out/etc/lightdm/web-greeter.yml"
    substituteInPlace src/settings.c \
    --replace '/usr/share/web-greeter/themes/' \
              "$out/usr/share/web-greeter/themes/"
    substituteInPlace data/web-greeter.yml \
    --replace '/usr/share/' \
              "$out/usr/share/"
    substituteInPlace data/web-greeter.yml \
    --replace 'theme: gruvbox' \
              "theme: litarvan"

    runHook postConfigure
  '';

buildPhase = ''
  meson setup build --prefix=$out -Dwith-webext-dir=$out/usr/lib/sea-greeter
  ninja -C build
'';

installPhase = ''
    meson install -C build --destdir=$out

    # So, for some reason, if I either don't do destdir=$out or prefix=$out for
    # the build, what happens is that either the bin/ or the config files copied
    # over from the setup don't appear in the final nix pkg. This means the only
    # way I've found to guarantee that every file is there to do both. This has
    # the problem that part of the files is double-"indented", meaning that the
    # nix store path is repeated with /nix/store/.../nix/store/.../bin. But
    # these files you can just move.
    NESTED_DIR=$(ls -d $out/nix/store/*)
    shopt -s dotglob
    mv $NESTED_DIR/* $out/
    rm -rf $out/nix

    # patch desktop executable reference
    substituteInPlace $out/usr/share/xgreeters/sea-greeter.desktop \
      --replace "Exec=sea-greeter" "Exec=$out/bin/sea-greeter"

    # the xserver.lightdm.greeter.package options expects the .desktop file to 
    # be on the root level. 
    ln -s $out/usr/share/xgreeters/sea-greeter.desktop $out/sea-greeter.desktop

    # install litarvan theme
    mkdir -p $out/usr/share/web-greeter/themes/litarvan
    tar -xzf ${themeSrc} -C $out/usr/share/web-greeter/themes/litarvan
    themeDir=$out/usr/share/web-greeter/themes/litarvan

    # lightdm java API changed (LLM found this)
    substituteInPlace $themeDir/js/app.8fe78afb.js \
      --replace 't.name.toLowerCase()===lightdm.language.toLowerCase()' \
                't.name.toLowerCase()===lightdm.language.name.toLowerCase()'

    # update authentication API (LLM found this)
    substituteInPlace $themeDir/js/app.8fe78afb.js \
      --replace 'submit:function(){var e=this;this.logging=!0,setTimeout((function(){lightdm_login(e.settings.user.username,e.password,(function(){setTimeout((function(){return lightdm_start(e.settings.desktop.key)}),400),e.$router.push(o.disableFade?"/base":"/intro/login")}),(function(){e.error=!0,e.password="",e.logging=!1}))}),150)}' \
      'submit:function(){this.logging=!0,window.lightdm.respond(this.password)}'

    substituteInPlace $themeDir/js/app.8fe78afb.js \
      --replace 'mounted:function(){window.addEventListener("keyup",this.keyup),setTimeout((function(){var e=document.querySelector("#password");e&&e.focus()}),650)}' \
      'mounted:function(){var e=this;window.addEventListener("keyup",this.keyup),window.lightdm.cancel_authentication(),window.lightdm.authenticate(e.settings.user.username),window.lightdm.authentication_complete.connect((function(){window.lightdm.is_authenticated?(setTimeout((function(){return window.lightdm.start_session(e.settings.desktop.key)}),400),e.$router.push(o.disableFade?"/base":"/intro/login")):(e.error=!0,e.password="",e.logging=!1,window.lightdm.cancel_authentication(),window.lightdm.authenticate(e.settings.user.username))})),setTimeout((function(){var t=document.querySelector("#password");t&&t.focus()}),650)}'

    # convert index.theme to index.yml 
    url=$(        grep '^url='   "$themeDir/index.theme" | cut -d= -f2- )

cat > "$themeDir/index.yml" <<EOF
primary_html: "$url"
secondary_html: "$url"
EOF
'';

  meta = with lib; {
    description = "Another LightDM greeter made with WebKitGTK2";
    homepage = "https://github.com/JezerM/sea-greeter";
    license = licenses.gpl3;
    platforms = platforms.linux;
    maintainers = [ JezerM ]; 
  };
}
