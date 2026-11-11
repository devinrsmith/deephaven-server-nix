# Deephaven Core server (server-jetty) release tarball, unpacked into the store.
# Not built from source: the upstream release artifact is self-contained (bin/start + lib/*.jar).
{ lib, stdenvNoCC, fetchurl, version, hash
# strict = true: fail the build if the release root holds anything but `expectedRoot`, so a new
# upstream layout is noticed rather than silently dropped. false: install everything.
, strict ? true
, expectedRoot ? [ "bin" "etc" "lib" ]
}:

stdenvNoCC.mkDerivation {
  pname = "deephaven-server-jetty";
  inherit version;

  src = fetchurl {
    url = "https://github.com/deephaven/deephaven-core/releases/download/v${version}/server-jetty-${version}.tar";
    inherit hash;
  };

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
  '' + lib.optionalString strict ''
    # The unpacked release root must contain exactly the expected entries (dotfiles included).
    actual=$(find . -mindepth 1 -maxdepth 1 -printf '%f\n' | LC_ALL=C sort)
    expected=${lib.escapeShellArg (lib.concatMapStrings (e: e + "\n") (lib.sort lib.lessThan expectedRoot))}
    expected=''${expected%$'\n'}
    if [ "$actual" != "$expected" ]; then
      echo "deephaven ${version}: unexpected release layout" >&2
      echo "expected root entries:" >&2; echo "$expected" >&2
      echo "actual root entries:" >&2; echo "$actual" >&2
      echo "pass strict = false to install everything, or update expectedRoot" >&2
      exit 1
    fi
  '' + ''
    mkdir -p $out
    cp -r . $out/
    rm -f $out/bin/start.bat
    runHook postInstall
  '';

  meta = {
    description = "Deephaven Community Core server (Jetty), release ${version}";
    homepage = "https://github.com/deephaven/deephaven-core";
    # Source-available, not OSI-approved. Marked non-free: consumers must allow this one package
    # by name (see `lib.allowUnfreePredicate`) instead of allowing all unfree software.
    license = {
      fullName = "Deephaven Community License Agreement";
      url = "https://github.com/deephaven/deephaven-core/blob/v${version}/LICENSE.md";
      free = false;
    };
    platforms = lib.platforms.unix;
  };
}
