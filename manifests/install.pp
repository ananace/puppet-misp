class misp::install inherits misp {

  require '::misp::dependencies'


  ## MISP
  #

  vcsrepo { $misp::install_dir:
    ensure     => present,
    provider   => git,
    submodules => true,
    force      => false,
    source     => $misp::misp_git_repo,
    revision   => $misp::misp_git_tag,
    owner      => $misp::default_user,
    group      => $misp::default_group,
    notify     => Exec['CakeResque require'],
  }

  exec {'git ignore permissions':
    command     => '/usr/bin/git config core.filemode false',
    cwd         => $misp::install_dir,
    refreshonly => true,
    subscribe   => Vcsrepo[$misp::install_dir],
    notify      => Vcsrepo["${misp::install_dir}/app/files/scripts/python-cybox","${misp::install_dir}/app/files/scripts/python-stix", "${misp::install_dir}/app/files/scripts/mixbox", "${misp::install_dir}/app/files/scripts/python-maec", "${misp::install_dir}/app/files/scripts/pydeep"],
  }


  ## Python plugins
  #

  vcsrepo {
    default:
      ensure   => present,
      provider => git,
      force    => false;

    "${misp::install_dir}/app/files/scripts/python-cybox":
      source   => $misp::cybox_git_repo,
      revision => $misp::cybox_git_tag;

    "${misp::install_dir}/app/files/scripts/python-stix":
      source   => $misp::stix_git_repo,
      revision => $misp::stix_git_tag;

    "${misp::install_dir}/app/files/scripts/mixbox":
      source   => $misp::mixbox_git_repo,
      revision => $misp::mixbox_git_tag;

    "${misp::install_dir}/app/files/scripts/python-maec":
      source   => $misp::maec_git_repo,
      revision => $misp::maec_git_tag;

    "${misp::install_dir}/app/files/scripts/pydeep":
      source   => $misp::pydeep_git_repo,
      revision => $misp::pydeep_git_tag;
  }

  exec {
    default:
      command     => '/usr/bin/git config core.filemode false && /usr/bin/python3.6 setup.py install',
      umask       => '0022',
      refreshonly => true;

    'python-cybox config':
      cwd       => "${misp::install_dir}/app/files/scripts/python-cybox/",
      unless    => '/usr/bin/pip3.6 list | grep cybox',
      subscribe => Vcsrepo["${misp::install_dir}/app/files/scripts/python-cybox"];

    'python-stix config':
      cwd       => "${misp::install_dir}/app/files/scripts/python-stix/",
      unless    => '/usr/bin/pip3.6 list | grep stix',
      subscribe => Vcsrepo["${misp::install_dir}/app/files/scripts/python-stix"];

    'mixbox config':
      cwd       => "${misp::install_dir}/app/files/scripts/mixbox/",
      unless    => '/usr/bin/pip3.6 list | grep mixbox',
      subscribe => Vcsrepo["${misp::install_dir}/app/files/scripts/mixbox"];

    'python-maec config':
      cwd       => "${misp::install_dir}/app/files/scripts/python-maec/",
      unless    => '/usr/bin/pip3.6 list | grep maec',
      subscribe => Vcsrepo["${misp::install_dir}/app/files/scripts/python-maec"];

    'pydeep build':
      command   => '/usr/bin/python3.6 setup.py build && /usr/bin/python3.6 setup.py install',
      cwd       => "${misp::install_dir}/app/files/scripts/pydeep/",
      unless    => '/usr/bin/pip3.6 list | grep pydeep',
      subscribe => Vcsrepo["${misp::install_dir}/app/files/scripts/pydeep"];
  }


  ## CakePHP
  #

  file { '/usr/share/httpd/.composer':
    ensure => directory,
    owner  => apache,
    group  => apache,
  }

  exec {
    default:
      cwd         => "${misp::install_dir}/app/",
      environment => ["COMPOSER_HOME=${misp::install_dir}/app/"],
      user        => 'apache',
      refreshonly => true;

    'CakeResque require':
      command => '/usr/bin/scl enable rh-php71 "php composer.phar require kamisama/cake-resque:4.1.2"',
      notify  => Exec['CakeResque config'];

    'CakeResque config':
      command => '/usr/bin/scl enable rh-php71 "php composer.phar config vendor-dir Vendor"',
      notify  => Exec['CakeResque install'];

    'CakeResque install':
      command => '/usr/bin/scl enable rh-php71 "php composer.phar install"',
      notify  => File["/etc/opt/rh/rh-${misp::php_version}/php-fpm.d/redis.ini", "/etc/opt/rh/rh-${misp::php_version}/php-fpm.d/timezone.ini"];
  }

  # file { "/etc/opt/rh/rh-${misp::php_version}/php-fpm.d/redis.ini":
  #   ensure  => file,
  #   content => 'extension=redis.so',
  # }

  # file { "/etc/opt/rh/rh-${misp::php_version}/php.d/99-redis.ini":
  #   ensure    => link,
  #   target    => "/etc/opt/rh/rh-${misp::php_version}/php-fpm.d/redis.ini",
  #   subscribe => File["/etc/opt/rh/rh-${misp::php_version}/php-fpm.d/redis.ini"],
  # }

  file { "/etc/opt/rh/rh-${misp::php_version}/php-fpm.d/timezone.ini":
    ensure  => file,
    content => "date.timezone = '${misp::timezone}'",
  }

  file { "/etc/opt/rh/rh-${misp::php_version}/php.d/99-timezone.ini":
    ensure    => link,
    target    => "/etc/opt/rh/rh-${misp::php_version}/php-fpm.d/timezone.ini",
    subscribe => File["/etc/opt/rh/rh-${misp::php_version}/php-fpm.d/timezone.ini"],
  }

  #File cration for managing workers

  file { "${misp::install_dir}/app/Console/worker/status.sh":
    ensure    => file,
    source    => "puppet:///modules/${module_name}/status.sh",
    owner     => $misp::default_high_user,
    group     => $misp::default_high_group,
    mode      => '0755',
    subscribe => Vcsrepo[$misp::install_dir],
  }

  # Logrotate

  #file {'/etc/logrotate.d/misp':
  #  ensure => file,
  #  source => "puppet:///modules/${module_name}/misp.logrotate",
  #  owner  => $misp::default_high_user,
  #  group  => $misp::default_high_group,
  #  mode   => '0755',
  #}

  #selinux::module{ 'misplogrotate':
  #  source    => "puppet:///modules/${module_name}/misplogrotate.te",
  #  subscribe => File['/etc/logrotate.d/misp'],
  #}
}
