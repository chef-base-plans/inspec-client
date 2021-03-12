pkg_name=inspec
pkg_origin=chef
pkg_version=4.27.1
pkg_description="InSpec is an open-source testing framework for infrastructure
  with a human- and machine-readable language for specifying compliance,
  security and policy requirements."
pkg_upstream_url=https://www.inspec.io/
pkg_maintainer="The Habitat Maintainers <humans@habitat.sh>"
pkg_source="https://github.com/inspec/inspec/archive/v${pkg_version}.tar.gz"
pkg_shasum=9d01bb6d30dbb5767d2b9d953dfa793944ed3fc1a2ae7729b2d039683d02bfc7
pkg_license=('Apache-2.0')
pkg_deps=(
  core/coreutils
  core/git
  core/ruby
  core/bash
)
pkg_build_deps=(
  core/gcc
  core/make
  core/readline
  core/sed
)
pkg_bin_dirs=(bin)

do_setup_environment() {
  build_line 'Setting GEM_HOME="$pkg_prefix/lib"'
  export GEM_HOME="$pkg_prefix/lib"

  build_line "Setting GEM_PATH=$GEM_HOME"
  export GEM_PATH="$GEM_HOME"
}

do_build() {
  pushd "$HAB_CACHE_SRC_PATH/$pkg_dirname/"
    gem build inspec.gemspec
    gem build inspec-core.gemspec
  popd
  pushd "$HAB_CACHE_SRC_PATH/$pkg_dirname/inspec-bin"
    gem build inspec-bin.gemspec
  popd
}

do_install() {
  # MUST install inspec first because inspec-bin depends on it via gemspec
  pushd "$HAB_CACHE_SRC_PATH/$pkg_dirname/"
    gem install inspec-*.gem --no-document
  popd
  pushd "$HAB_CACHE_SRC_PATH/$pkg_dirname/inspec-bin"
    gem install inspec-bin*.gem --no-document
  popd

  wrap_inspec_bin

  # Certain gems (timeliness) are getting installed with world writable files
  # This is removing write bits for group and other.
  find "$GEM_HOME" -xdev -perm -0002 -type f -print 2>/dev/null | xargs -I '{}' chmod go-w '{}'
}

# Need to wrap the InSpec binary to ensure paths are correct
wrap_inspec_bin() {
  local bin="$pkg_prefix/bin/$pkg_name"
  local real_bin="$GEM_HOME/gems/inspec-bin-${pkg_version}/bin/inspec"
  build_line "Adding wrapper $bin to $real_bin"
  cat <<EOF > "$bin"
#!$(pkg_path_for core/bash)/bin/bash
set -e

# Set binary path that allows InSpec to use non-Hab pkg binaries
export PATH="/sbin:/usr/sbin:/usr/local/sbin:/usr/local/bin:/usr/bin:/bin:$PATH"

# Set Ruby paths defined from 'do_setup_environment()'
export GEM_HOME="$GEM_HOME"
export GEM_PATH="$GEM_PATH"

exec $(pkg_path_for core/ruby)/bin/ruby $real_bin \$@
EOF
  chmod -v 755 "$bin"
}

do_strip() {
  return 0
}
