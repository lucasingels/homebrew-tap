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
  version "0.3.2"
  sha256 "1e9ea653612a4c2a771e298c13ad11319e31a9db0ef8346507ef1836a9eafcd8"

  bottle do
    root_url "https://github.com/lucasingels/sapling/releases/download/v0.3.2"
    sha256 arm64_tahoe: "bc200395ab75d64f40d2c7f0efa50242b798595687c5910536e1470fee1177ea"
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

    python = Formula["python@3.12"].opt_prefix/"bin/python3.12"

    cd "eden/scm" do
      system "rustup-init -y"
      system "source /Users/runner/Library/Caches/Homebrew/cargo_cache/env && rustup target add aarch64-apple-darwin"
      system "source /Users/runner/Library/Caches/Homebrew/cargo_cache/env && "\
             "#{python} ./build.py --oss --with-python #{python} "\
             "--with-version 0.3.2 --rust-target aarch64-apple-darwin"
      bin.install "out/sl"
      lib.install "out/isl-dist.tar.xz"
    end

    libexec.install "#{prefix}/bin/sl"
    libexec.install "#{lib}/isl-dist.tar.xz"

    (bin/"sl").write <<~EOS
      #!/bin/bash
      exec "#{opt_libexec}/sl" --config "web.isl-dist-path=#{opt_libexec}/isl-dist.tar.xz" "$@"
    EOS
  end
end
