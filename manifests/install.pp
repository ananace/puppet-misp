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
    notify     => Exec['Pear install Console_CommandLine', 'Pear install Crypt_GPG', 'CakeResque require'],
  }
  # To stop the diagnostics complaints in MISP
  file { "${misp::install_dir}/.git/ORIG_HEAD":
    ensure  => file,
    content => '',
    owner   => $misp::default_user,
    group   => $misp::default_group,
    seltype => 'httpd_sys_rw_content_t',
    replace => false,
    require => Vcsrepo[$misp::install_dir],
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

  python::pyvenv { $misp::venv_dir:
    ensure  => present,
    version => '3.6',
    owner   => $misp::default_user,
    group   => $misp::default_group,
    path    => ['/opt/rh/rh-python36/root/bin/', '/opt/rh/rh-python36/root/usr/bin/', '/opt/rh/rh-python36/root/usr/sbin/'],
  }

  python::pip {
    default:
      virtualenv => $misp::venv_dir,
      owner      => $misp::default_user,
      group      => $misp::default_group;

    'python-dateutil':;
    'python-magic':;
    'lxml':;
    'siz':;
    'zmq':;
  }


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

  $venv = "${misp::install_dir}/venv/bin/"

  exec {
    default:
      command     => "/usr/bin/git config core.filemode false && ${venv}/bin/python setup.py install",
      umask       => '0022',
      refreshonly => true,
      require     => Exec['Create virtualenv'];

    'python-cybox config':
      cwd       => "${misp::install_dir}/app/files/scripts/python-cybox/",
      unless    => "${venv}/bin/pip3 list | /bin/grep cybox",
      subscribe => Vcsrepo["${misp::install_dir}/app/files/scripts/python-cybox"];

    'python-stix config':
      cwd       => "${misp::install_dir}/app/files/scripts/python-stix/",
      unless    => "${venv}/bin/pip3 list | /bin/grep stix",
      subscribe => Vcsrepo["${misp::install_dir}/app/files/scripts/python-stix"];

    'mixbox config':
      cwd       => "${misp::install_dir}/app/files/scripts/mixbox/",
      unless    => "${venv}/bin/pip3 list | /bin/grep mixbox",
      subscribe => Vcsrepo["${misp::install_dir}/app/files/scripts/mixbox"];

    'python-maec config':
      cwd       => "${misp::install_dir}/app/files/scripts/python-maec/",
      unless    => "${venv}/bin/pip3 list | /bin/grep maec",
      subscribe => Vcsrepo["${misp::install_dir}/app/files/scripts/python-maec"];

    'pydeep build':
      command   => "${venv}/bin/python setup.py build && ${venv}/bin/python setup.py install",
      cwd       => "${misp::install_dir}/app/files/scripts/pydeep/",
      unless    => "${venv}/bin/pip3 list | /bin/grep pydeep",
      subscribe => Vcsrepo["${misp::install_dir}/app/files/scripts/pydeep"];
  }

  ## Pears
  #

  $run_php = "/usr/bin/scl enable rh-${misp::php_version}"

  exec {
    default:
      cwd         => "${misp::install_dir}/",
      refreshonly => true;

    'Pear install Console_CommandLine':
      command => "${run_php} 'pear install ${misp::install_dir}/INSTALL/dependencies/Console_CommandLine/package.xml'";

    'Pear install Crypt_GPG':
      command => "${run_php} 'pear install ${misp::install_dir}/INSTALL/dependencies/Crypt_GPG/package.xml'";
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
      command => "${run_php} 'php composer.phar require kamisama/cake-resque:4.1.2'",
      notify  => Exec['CakeResque config'];

    'CakeResque config':
      command => "${run_php} 'php composer.phar config vendor-dir Vendor'",
      notify  => Exec['CakeResque install'];

    'CakeResque install':
      command => "${run_php} 'php composer.phar install'",
      notify  => File["/etc/opt/rh/rh-${misp::php_version}/php-fpm.d/timezone.ini"];
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
