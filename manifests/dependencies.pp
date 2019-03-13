class misp::dependencies inherits misp {
  ensure_packages( [
      'gcc', # Needed for compiling Python modules
      'git', # Needed for pulling the MISP code and those for some dependencies
      'zip',
      'libxslt-devel', 'zlib-devel',
      'ssdeep', 'ssdeep-libs', 'ssdeep-devel', #For pydeep

      "rh-${misp::php_version}", "rh-${misp::php_version}-php-fpm", "rh-${misp::php_version}-php-devel", "rh-${misp::php_version}-php-mysqlnd", "rh-${misp::php_version}-php-mbstring", "rh-${misp::php_version}-php-pear", "rh-${misp::php_version}-php-xml", "rh-${misp::php_version}-php-bcmath", # PHP related packages
      "sclo-${misp::php_version}-php-pecl-redis4", # Redis connection from PHP
  ] )

  if $misp::install_mariadb {
    ensure_resource('package', $misp::mariadb_scl, {})
  }
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
  }
  if $misp::manage_haveged {
    ensure_packages( ['haveged'] )
  }

  if $misp::pymisp_rpm {
    ensure_packages( ['pymisp'] )
  }

  if $misp::build_lief {
    ensoure_resource('package', ['devtoolset-7', 'cmake3'], {})
  }
  elsif $misp::lief {
    ensure_packages( [$misp::lief_package_name] )
  }
}
