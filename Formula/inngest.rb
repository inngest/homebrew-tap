class Inngest < Formula
  desc "Inngest CLI and development server"
  homepage "https://www.inngest.com/"
  url "https://github.com/inngest/inngest.git",
      tag:      "v1.15.1",
      revision: "196512c9bca5fa8a77e4ea78446094a975096bac"
  license :cannot_represent # See https://github.com/inngest/inngest/blob/main/LICENSE.md
  head "https://github.com/inngest/inngest.git", branch: "main" # brew install --build-from-source --formula inngest/tap/inngest --HEAD

  depends_on "go" => :build
  depends_on "node" => :build
  depends_on "pnpm" => :build

  def install
    # Initialize submodules (for embedded docs)
    system "git", "submodule", "update", "--init", "--recursive"

    # Build the frontend UI (gets embedded in the Go binary)
    cd "ui/apps/dev-server-ui" do
      system "pnpm", "install", "--frozen-lockfile"
      system "pnpm", "build"
    end

    # Copy built UI to static directory for embedding
    cp_r "ui/apps/dev-server-ui/dist/.", "pkg/devserver/static/"

    # Prepare version tag
    short_commit = Utils.safe_popen_read("git", "rev-parse", "--short=7", "HEAD").chomp
    ldflags = "-s -w -X github.com/inngest/inngest/pkg/inngest/version.Version=#{version} -X github.com/inngest/inngest/pkg/inngest/version.Hash=#{short_commit}"

    # Build the Go binary
    system "go", "build", *std_go_args(ldflags:, output: bin/"inngest"), "./cmd"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/inngest version")
  end
end
