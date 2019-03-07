class misp::dependencies inherits misp {
  ensure_packages( [
      'gcc', # Needed for compiling Python modules
      'git', # Needed for pulling the MISP code and those for some dependencies
      'zip', 'mariadb',
      'libxslt-devel', 'zlib-devel',
      'php-mbstring', #Required for Crypt_GPG
      'php-pear-crypt-gpg', # Crypto GPG
      'ssdeep', 'ssdeep-libs', 'ssdeep-devel', #For pydeep

      "rh-${misp::php_version}", "rh-${misp::php_version}-php-fpm", "rh-${misp::php_version}-php-devel", "rh-${misp::php_version}-php-mysqlnd", "rh-${misp::php_version}-php-mbstring", 'php-pear', "rh-${misp::php_version}-php-xml", "rh-${misp::php_version}-php-bcmath", # PHP related packages
      "sclo-${misp::php_version}-php-pecl-redis4", # Redis connection from PHP
  ] )

  ensure_packages( [
      'python-magic',
      'lxml', 'python-dateutil', 'zmq'
    ], {
      provider => 'pip3',
  })

  if $misp::manage_scl {
    ensure_resource('package', 'centos-release-scl', {
        before => Package[
          "rh-${misp::php_version}", "rh-${misp::php_version}-php-fpm", "rh-${misp::php_version}-php-devel",
          "rh-${misp::php_version}-php-mysqlnd", "rh-${misp::php_version}-php-mbstring", "rh-${misp::php_version}-php-xml",
          "rh-${misp::php_version}-php-bcmath", "sclo-${misp::php_version}-php-pecl-redis"
        ],
    })
  }
  if $misp::manage_python {
    ensure_packages( ['rh-python36', 'rh-python36-python-devel', 'rh-python36-python-pip', 'rh-python36-python-six'] )
    # To allow for "sanely" installing packages with Puppet
    if !defined(File['/usr/bin/pip3']) {
      file { '/usr/bin/pip3':
        ensure  => link,
        target  => '/opt/rh/rh-python36/bin/pip3.6',
        replace => false,
      }
    }
  }
  if $misp::manage_haveged {
    ensure_packages( ['haveged'] )
  }

  if $misp::pymisp_rpm {
    ensure_packages( ['pymisp'] )
  } else {
    ensure_packages( ['pymisp'], {
        'ensure'   => 'present',
        'provider' => 'pip3',
    })
  }

  if $misp::lief {
    ensure_packages( [$misp::lief_package_name] )
  }
}
