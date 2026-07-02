{
  stdenv,
  lib,
  libGL,
  xorgproto,
  libx11,
  libxext,
  libxi,
  libxfixes,
  libxcursor,
  alsa-lib,
  sokolVersion,
}:
let
  sokolLibs = [
    {
      pname = "sokol-log";
      src = "sokol_log";
      dst = "sokol_log_linux_x64_gl";
    }
    {
      pname = "sokol-gfx";
      src = "sokol_gfx";
      dst = "sokol_gfx_linux_x64_gl";
      flags = "-I${libGL.dev}/include";
    }
    {
      pname = "sokol-app";
      src = "sokol_app";
      dst = "sokol_app_linux_x64_gl";
      flags = "-I${libGL.dev}/include -I${libx11.dev}/include -I${xorgproto}/include -I${libxi.dev}/include -I${libxext.dev}/include -I${libxfixes.dev}/include -I${libxcursor.dev}/include";
    }
    {
      pname = "sokol-glue";
      src = "sokol_glue";
      dst = "sokol_glue_linux_x64_gl";
    }
    {
      pname = "sokol-time";
      src = "sokol_time";
      dst = "sokol_time_linux_x64_gl";
    }
    {
      pname = "sokol-audio";
      src = "sokol_audio";
      dst = "sokol_audio_linux_x64_gl";
      flags = "-I${alsa-lib.dev}/include -L${alsa-lib}/lib -lasound";
    }
    {
      pname = "sokol-debugtext";
      src = "sokol_debugtext";
      dst = "sokol_debugtext_linux_x64_gl";
    }
    {
      pname = "sokol-shape";
      src = "sokol_shape";
      dst = "sokol_shape_linux_x64_gl";
    }
    {
      pname = "sokol-gl";
      src = "sokol_gl";
      dst = "sokol_gl_linux_x64_gl";
    }
  ];
  modes = [
    {
      mode.name = "debug";
      mode.flags = "-g";
      mode.dstSuffix = "_debug";
    }
    # Release
    {
      mode.name = "release";
      mode.flags = "-O2 -DNDEBUG";
      mode.dstSuffix = "_release";
    }
  ];
  merged = builtins.concatMap (lib: builtins.map (mode: lib // mode) modes) sokolLibs;
  buildPackage = (
    {
      pname,
      src,
      dst,
      flags ? "",
      mode,
    }:
    {
      name = "${pname}-${mode.name}";
      value = stdenv.mkDerivation {
        pname = "${pname}-${mode.name}";
        version = sokolVersion;
        src = ../sokol/c;
        buildPhase = ''
          runHook preBuild

          gcc -pthread -c ${mode.flags} -DIMPL -DSOKOL_GLCORE ${flags} ${src}.c
          ar rcs ${dst}.a ${src}.o
          gcc -pthread -shared -fPIC ${mode.flags} -DIMPL -DSOKOL_GLCORE ${flags} -o ${dst}.so ${src}.c

          runHook postBuild
        '';
        installPhase = ''
          runHook preInstall

          mkdir -p "$out/lib"
          cp ${dst}.a $out/lib/${dst}${mode.dstSuffix}.a
          cp ${dst}.so $out/lib/${dst}${mode.dstSuffix}.so

          runHook postInstall
        '';
      };
    }
  );
in
lib.listToAttrs (lib.forEach merged buildPackage)
