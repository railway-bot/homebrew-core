class Pycodestyle < Formula
  include Language::Python::Shebang

  desc "Simple Python style checker in one Python file"
  homepage "https://pycodestyle.pycqa.org/"
  url "https://github.com/PyCQA/pycodestyle/archive/2.9.0.tar.gz"
  sha256 "de1438a604f234065f446f45069ef908c007084b1d3abe2e2f89c98ab6fb9d25"
  license "MIT"
  head "https://github.com/PyCQA/pycodestyle.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, all: "0bfbdf6b8b775bee4c74133d92225bfcf3c4f22d55e9d0c9814f96b38ebfe613"
  end

  depends_on "python@3.10"

  def install
    rewrite_shebang detected_python_shebang, "pycodestyle.py"
    bin.install "pycodestyle.py" => "pycodestyle"
  end

  test do
    # test invocation on a file with no issues
    (testpath/"ok.py").write <<~EOS
      print(1)
    EOS
    assert_equal "",
      shell_output("#{bin}/pycodestyle ok.py")

    # test invocation on a file with a whitespace style issue
    (testpath/"ws.py").write <<~EOS
      print( 1)
    EOS
    assert_equal "ws.py:1:7: E201 whitespace after '('\n",
      shell_output("#{bin}/pycodestyle ws.py", 1)

    # test invocation on a file with an import not at top of file
    (testpath/"imp.py").write <<~EOS
      pass
      import sys
    EOS
    assert_equal "imp.py:2:1: E402 module level import not at top of file\n",
      shell_output("#{bin}/pycodestyle imp.py", 1)
  end
end
