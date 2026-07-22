# Copyright (c) Meta Platforms, Inc. and affiliates.
#
# This software may be used and distributed according to the terms of the
# GNU General Public License version 2.

# This is an example brew formula. It will need to be updated to point to an
# actual URL, with an actual sha256, license, and tests.
class SaplingDev < Formula
  desc "The Sapling source control client"
  homepage "https://sapling-scm.com"
  license "GPL-2.0-or-later"
  # These fields are intended to be populated by a Github action
  url "file:///Users/runner/work/sapling/sapling/sapling.tar.gz"
  version "0.3"
  sha256 "f49d238e864ad7967c1c7c333041be3d88b7367b4cdb0f91589cd34c4662c906"

  bottle do
    root_url "https://github.com/lucasingels/sapling/releases/download/v0.3"
    sha256 arm64_tahoe: "2a7ba7929db07c7f07bc0ea647b75b23d31569b0564d28edb9bf704eb57a2551"
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
             "--with-version 0.3 --rust-target aarch64-apple-darwin"
      bin.install "out/sl"
      lib.install "out/isl-dist.tar.xz"
    end

    libexec.install "#{prefix}/bin/sl"
    libexec.install "#{lib}/isl-dist.tar.xz"

    (bin/"sld").write <<~EOS
      #!/bin/bash
      exec "#{opt_libexec}/sl" --config "web.isl-dist-path=#{opt_libexec}/isl-dist.tar.xz" "$@"
    EOS
  end
end
