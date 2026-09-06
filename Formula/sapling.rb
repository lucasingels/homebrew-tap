# Copyright (c) Meta Platforms, Inc. and affiliates.
#
# This software may be used and distributed according to the terms of the
# GNU General Public License version 2.

# This is an example brew formula. It will need to be updated to point to an
# actual URL, with an actual sha256, license, and tests.
class Sapling < Formula
  desc "The Sapling source control client"
  homepage "https://sapling-scm.com"
  license "GPL-2.0-or-later"
  # These fields are intended to be populated by a Github action
  url "file:///Users/runner/work/sapling/sapling/sapling.tar.gz"
  version "0.3.6"
  sha256 "e57209cc7d88d7cc53a97d8c3c6fb904d1e2851aa987ea23ed8b2a3df7cfd7a3"

  bottle do
    root_url "https://github.com/lucasingels/sapling/releases/download/v0.3.6"
    sha256 arm64_tahoe: "9c99c372dbb59fc94d6b824a225f618147281dc2bad854eec1b44ba43f200a55"
  end

  depends_on "python@3.12"
  depends_on "node"
  depends_on "openssl@3"
  depends_on "gh"
  depends_on "cmake" => :build
  depends_on "rustup" => :build
  depends_on "yarn" => :build

  def install
    # We use the openssl rust crate, which has its own mechanism for figuring
    # out where the OpenSSL installation is.
    # According to  https://docs.rs/openssl/latest/openssl/#manual , we can
    # force some specific location by setting the OPENSSL_DIR environment
    # variable. This is necessary since the installed OpenSSL library
    # might not match the architecture of the destination one.
    ENV["OPENSSL_DIR"] = Formula["openssl@3"].opt_prefix
    ENV["CFLAGS"] = "--target=aarch64-apple-darwin"
    # The line below is necessary, since otherwise homebrew somehow injects
    # -march=... into clang
    ENV["HOMEBREW_OPTFLAGS"] = ""
    # Some dependencies (e.g. smallvec's "specialization" feature) rely on
    # unstable rustc features. RUSTC_BOOTSTRAP=1 lets the stable toolchain
    # compile them, matching the getdeps build (fbcode_builder/getdeps/cargo.py).
    ENV["RUSTC_BOOTSTRAP"] = "1"

    # The release workflow routes rustc through sccache so crates whose inputs
    # are unchanged come from the GitHub Actions cache instead of being rebuilt.
    # Homebrew scrubs the environment before running a formula and only lets
    # HOMEBREW_* variables through, so the workflow hands the sccache binary over
    # under that prefix. The wrapper mirrors Homebrew's own rustc shim
    # (Library/Homebrew/shims/shared/rustc_wrapper, which appends
    # HOMEBREW_RUSTFLAGS) with sccache in front of the compiler.
    sccache = ENV.fetch("HOMEBREW_SAPLING_SCCACHE", "")
    unless sccache.empty?
      wrapper = buildpath/"sccache_rustc_wrapper"
      wrapper.write <<~EOS
        #!/bin/bash
        read -ra RUSTFLAGS <<<"${HOMEBREW_RUSTFLAGS:-}"
        exec "#{sccache}" "$@" "${RUSTFLAGS[@]}"
      EOS
      wrapper.chmod 0755
      ENV["RUSTC_WRAPPER"] = wrapper.to_s
    end

    python = Formula["python@3.12"].opt_prefix/"bin/python3.12"

    cd "eden/scm" do
      system "rustup-init -y"
      system "source /Users/runner/Library/Caches/Homebrew/cargo_cache/env && rustup target add aarch64-apple-darwin"
      system "source /Users/runner/Library/Caches/Homebrew/cargo_cache/env && "\
             "#{python} ./build.py --oss --with-python #{python} "\
             "--with-version 0.3.6 --rust-target aarch64-apple-darwin"
      bin.install "out/sl"
      lib.install "out/isl-dist.tar.xz"
    end

    libexec.install "#{prefix}/bin/sl"
    libexec.install "#{lib}/isl-dist.tar.xz"

    (bin/"sl").write <<~EOS
      #!/bin/bash
      # `sl --version` is only recognised as the first argument; keep it there.
      if [ "${1:-}" = "--version" ]; then
        exec "#{opt_libexec}/sl" "$@"
      fi
      exec "#{opt_libexec}/sl" --config "web.isl-dist-path=#{opt_libexec}/isl-dist.tar.xz" "$@"
    EOS
  end
end
