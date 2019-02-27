class misp::dependencies inherits misp {
  ensure_packages( [
      'gcc', # Needed for compiling Python modules
      'git', # Needed for pulling the MISP code and those for some dependencies
      'zip', 'mariadb',
      'libxslt-devel', 'zlib-devel',
      'php-mbstring', #Required for Crypt_GPG
      'php-pear-crypt-gpg', # Crypto GPG
      'python36-six', # Python related packages
      'ssdeep', 'ssdeep-libs', 'ssdeep-devel', #For pydeep

      "rh-${misp::php_version}", "rh-${misp::php_version}-php-fpm", "rh-${misp::php_version}-php-devel", "rh-${misp::php_version}-php-mysqlnd", "rh-${misp::php_version}-php-mbstring", 'php-pear', "rh-${misp::php_version}-php-xml", "rh-${misp::php_version}-php-bcmath", # PHP related packages
      "sclo-${misp::php_version}-php-pecl-redis", # Redis connection from PHP
  ] )

  ensure_packages( [
      'python-magic',
      'lxml', 'python-dateutil', 'zmq'
    ], {
      provider => 'pip3',
  })

  if $misp::manage_python {
    ensure_packages( ['python36', 'python36-pip'] )
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
