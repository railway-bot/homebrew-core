class Dynare < Formula
  desc "Platform for economic models, particularly DSGE and OLG models"
  homepage "https://www.dynare.org/"
  license "GPL-3.0-or-later"
  revision 1

  # Remove when patch is no longer needed.
  stable do
    url "https://www.dynare.org/release/source/dynare-5.2.tar.xz"
    sha256 "01849a45d87cac3c1a8e8bf55030d026054ffb9b1ebf5ec09c9981a08d60f55c"

    on_arm do
      # Needed since we patch a `Makefile.am` below.
      depends_on "autoconf" => :build
      depends_on "automake" => :build
      depends_on "bison" => :build
      depends_on "flex" => :build

      # Fixes a build error on ARM.
      # Remove the `Hardware::CPU.arm?` in the `autoreconf` call below when this is removed.
      patch do
        url "https://git.dynare.org/Dynare/preprocessor/-/commit/e0c3cb72b7337a5eecd32a77183af9f1609a86ef.diff"
        sha256 "4fe156dce78fba9ec280bceff66f263c3a9dbcd230cc5bac96b5a59c14c7554f"
        directory "preprocessor"
      end
    end
  end

  livecheck do
    url "https://www.dynare.org/download/"
    regex(/href=.*?dynare[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 cellar: :any, arm64_monterey: "577765a34cad796a8cd5c4af4e1d840bb227e32622da7938f8a8f88e0009f192"
    sha256 cellar: :any, arm64_big_sur:  "9fdf81f60dc8000844a09b14bf1bfba19d527598eed242045aa9f58bdfc7bce1"
    sha256 cellar: :any, monterey:       "6cea8b141d86b09e4cc8d66599271a4ce43b8160614c751f11eb5f54a6368f8a"
    sha256 cellar: :any, big_sur:        "708994cc5337116c60a58b37250b4381babbb3880ba9856880614863497e2d72"
    sha256 cellar: :any, catalina:       "b06faa15aac9723dc15dd350de4ff846dd201ad71a338a0222f7b7acf6f3dafd"
    sha256               x86_64_linux:   "ce6f2cb07b981c5ac0eb1b17a2d07b6279da54f0a22c71bea842e5c70f595101"
  end

  head do
    url "https://git.dynare.org/Dynare/dynare.git", branch: "master"

    depends_on "autoconf" => :build
    depends_on "automake" => :build
    depends_on "bison" => :build
    depends_on "flex" => :build
  end

  depends_on "boost" => :build
  depends_on "cweb" => :build
  depends_on "fftw"
  depends_on "gcc"
  depends_on "gsl"
  depends_on "hdf5"
  depends_on "libmatio"
  depends_on "metis"
  depends_on "octave"
  depends_on "openblas"
  depends_on "suite-sparse"

  resource "io" do
    url "https://octave.sourceforge.io/download.php?package=io-2.6.4.tar.gz", using: :nounzip
    sha256 "a74a400bbd19227f6c07c585892de879cd7ae52d820da1f69f1a3e3e89452f5a"
  end

  resource "slicot" do
    url "https://deb.debian.org/debian/pool/main/s/slicot/slicot_5.0+20101122.orig.tar.gz"
    sha256 "fa80f7c75dab6bfaca93c3b374c774fd87876f34fba969af9133eeaea5f39a3d"
  end

  resource "statistics" do
    url "https://octave.sourceforge.io/download.php?package=statistics-1.4.3.tar.gz", using: :nounzip
    sha256 "9801b8b4feb26c58407c136a9379aba1e6a10713829701bb3959d9473a67fa05"
  end

  def install
    ENV.cxx11

    resource("slicot").stage do
      system "make", "lib", "OPTS=-fPIC", "SLICOTLIB=../libslicot_pic.a",
             "FORTRAN=gfortran", "LOADER=gfortran"
      system "make", "clean"
      system "make", "lib", "OPTS=-fPIC -fdefault-integer-8",
             "FORTRAN=gfortran", "LOADER=gfortran",
             "SLICOTLIB=../libslicot64_pic.a"
      (buildpath/"slicot/lib").install "libslicot_pic.a", "libslicot64_pic.a"
    end

    # GCC is the only compiler supported by upstream
    # https://git.dynare.org/Dynare/dynare/-/blob/master/README.md#general-instructions
    gcc = Formula["gcc"]
    gcc_major_ver = gcc.any_installed_version.major
    ENV["CC"] = Formula["gcc"].opt_bin/"gcc-#{gcc_major_ver}"
    ENV["CXX"] = Formula["gcc"].opt_bin/"g++-#{gcc_major_ver}"
    ENV.append "LDFLAGS", "-static-libgcc"

    # Remove `Hardware::CPU.arm?` when the patch is no longer needed.
    system "autoreconf", "--force", "--install", "--verbose" if build.head? || Hardware::CPU.arm?
    system "./configure", *std_configure_args,
                          "--disable-silent-rules",
                          "--disable-doc",
                          "--disable-matlab",
                          "--with-boost=#{Formula["boost"].prefix}",
                          "--with-gsl=#{Formula["gsl"].prefix}",
                          "--with-matio=#{Formula["libmatio"].prefix}",
                          "--with-slicot=#{buildpath}/slicot"

    # Octave hardcodes its paths which causes problems on GCC minor version bumps
    flibs = "-L#{gcc.lib}/gcc/#{gcc_major_ver} -lgfortran -lquadmath -lm"
    system "make", "install", "FLIBS=#{flibs}"
  end

  def caveats
    <<~EOS
      To get started with Dynare, open Octave and type
        addpath #{opt_lib}/dynare/matlab
    EOS
  end

  test do
    ENV.cxx11

    statistics = resource("statistics")
    io = resource("io")
    testpath.install statistics, io

    cp lib/"dynare/examples/bkk.mod", testpath

    (testpath/"dyn_test.m").write <<~EOS
      pkg prefix #{testpath}/octave
      pkg install io-#{io.version}.tar.gz
      pkg install statistics-#{statistics.version}.tar.gz
      dynare bkk.mod console
    EOS

    system Formula["octave"].opt_bin/"octave", "--no-gui",
           "-H", "--path", "#{lib}/dynare/matlab", "dyn_test.m"
  end
end
