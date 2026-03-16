class SaplingDev < Formula
  desc "The Sapling source control client"
  homepage "https://sapling-scm.com"
  license "GPL-2.0-or-later"
  url "https://github.com/lucasingels/sapling/releases/download/v0.1.4/sapling-dev-0.1.4.arm64.bottle.tar.gz"
  sha256 "1ae1fe4f69542238baf6ccbb61409c0815e8d68cad1d03d5aae3dd4004647fee"
  version "0.1.4"

  bottle do
    root_url "https://github.com/lucasingels/sapling/releases/download/v0.1.4"
    sha256 cellar: :any, arm64_tahoe:   "1ae1fe4f69542238baf6ccbb61409c0815e8d68cad1d03d5aae3dd4004647fee"
    sha256 cellar: :any, arm64_sequoia: "1ae1fe4f69542238baf6ccbb61409c0815e8d68cad1d03d5aae3dd4004647fee"
  end

  depends_on "python@3.11"
  depends_on "node"
  depends_on "openssl@3"
  depends_on "gh"
end
