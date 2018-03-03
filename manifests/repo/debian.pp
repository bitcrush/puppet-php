# Configure debian apt repo
#
# === Parameters
#
# [*location*]
#   Location of the apt repository
#
# [*release*]
#   Release of the apt repository
#
# [*repos*]
#   Apt repository names
#
# [*include_src*]
#   Add source source repository
#
# [*key*]
#   Public key in apt::key format
#
class php::repo::debian (
  Boolean                   $include_src = false,
  Optional[Stdlib::Httpurl] $location    = undef,
  Optional[String[1]]       $release     = undef,
  Optional[String[1]]       $repos       = undef,
  Optional[Hash]            $key         = undef,
) {
  if $caller_module_name != $module_name {
    warning('php::repo::debian is private')
  }

  include apt

  # Required for HTTPS URLs (apt-transport-https is ensured by the puppetlabs-apt module)
  unless $key.dig('source') =~ /\Ahttp:/ and $location =~ /\Ahttp:/ {
    ensure_packages(['ca-certificates'], { 'ensure' => 'present' })
    $require_https_pkgs = Package['ca-certificates']
  }

  case $facts['os']['distro']['codename'] {
    'wheezy': {
      $version_string = $php::globals::php_version.regsubst('\.', '')

      # Add dotdeb key + repository
      apt::key { 'php::repo::debian':
        id      => pick($key.dig('id'), '6572BBEF1B5FF28B28B706837E3F070089DF5277'),
        source  => pick($key.dig('source'), 'https://www.dotdeb.org/dotdeb.gpg'),
        require => $require_https_pkgs,
      }

      apt::source { 'dotdeb-wheezy':
        location => pick($location, 'https://packages.dotdeb.org'),
        release  => 'wheezy',
        repos    => pick($repos, 'all'),
        include  => {
          'src' => $include_src,
          'deb' => true,
        },
        require  => Apt::Key['php::repo::debian'],
      }
      apt::source { "dotdeb-wheezy-php${version_string}":
        location => pick($location, 'https://packages.dotdeb.org'),
        release  => "wheezy-php${version_string}",
        repos    => pick($repos, 'all'),
        include  => {
          'src' => $include_src,
          'deb' => true,
        },
        require  => Apt::Key['php::repo::debian'],
      }
    }
    'jessie', 'stretch': {
      # Add sury key + repository
      apt::key { 'php::repo::debian':
        id      => pick($key.dig('id'), 'DF3D585DB8F0EB658690A554AC0E47584A7A714D'),
        source  => pick($key.dig('source'), 'https://packages.sury.org/php/apt.gpg'),
        require => $require_https_pkgs,
      }

      apt::source { 'sury-php':
        location => pick($location, 'https://packages.sury.org/php/'),
        release  => $facts['os']['distro']['codename'],
        repos    => pick($repos, 'main'),
        include  => {
          'src' => $include_src,
          'deb' => true,
        },
        require  => Apt::Key['php::repo::debian'],
      }
    }
    default: {
      fail("Unsupported Debian distribution: ${facts['os']['distro']['codename']}")
    }
  }
}
