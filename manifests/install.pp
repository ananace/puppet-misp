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

  exec { 'Create virtualenv':
    command => "/usr/bin/scl enable rh-python36 'python -m venv ${misp::venv_dir}'",
    creates => "${misp::venv_dir}/bin/activate",
    user    => $misp::default_user,
    require => Vcsrepo[$misp::install_dir],
  }

  exec {
    default:
      umask   => '0022',
      path    => [ "${misp::venv_dir}/bin" ],
      user    => $misp::default_user,
      require => Exec['Create virtualenv'];

    'python-dateutil':
      command => 'pip install python-dateutil',
      unless  => 'pip freeze --all | /bin/grep python-dateutil=';

    'python-magic':
      command => 'pip install python-magic',
      unless  => 'pip freeze --all | /bin/grep python-magic=';

    'enum34':
      command => 'pip install enum34',
      unless  => 'pip freeze --all | /bin/grep enum34=';

    'lxml':
      command => 'pip install lxml',
      unless  => 'pip freeze --all | /bin/grep lxml=';

    'siz':
      command => 'pip install six',
      unless  => 'pip freeze --all | /bin/grep six=';

    'zmq':
      command => 'pip install zmq',
      unless  => 'pip freeze --all | /bin/grep zmq=';

    'stix':
      command => 'pip install stix',
      unless  => 'pip freeze --all | /bin/grep stix=';

    'stix2 v1.1.1':
      command => 'pip install stix2==1.1.1',
      unless  => 'pip freeze --all | /bin/grep stix2==1.1.1';

    'pymisp':
      command => 'pip install pymisp',
      unless  => 'pip freeze --all | /bin/grep pymisp=';
  }


  vcsrepo {
    default:
      ensure   => present,
      owner    => $misp::default_user,
      group    => $misp::default_group,
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

  if $misp::build_lief {
    vcsrepo { "${misp::install_dir}/app/files/scripts/lief":
      ensure   => present,
      owner    => $misp::default_user,
      group    => $misp::default_group,
      source   => $misp::lief_git_repo,
      revision => $misp::lief_git_tag,
      provider => git,
      force    => false,
    }

    exec {
      default:
        cwd         => "${misp::install_dir}/app/files/scripts/lief/build",
        user        => $misp::default_user,
        refreshonly => true;

      'ensure build dir':
        cwd     => '/',
        command => "/bin/mkdir '${misp::install_dir}/app/files/scripts/lief/build'",
        creates => "${misp::install_dir}/app/files/scripts/lief/build",
        require => Vcsrepo["${misp::install_dir}/app/files/scripts/lief"];

      'set up LIEF build':
        command   => '/usr/bin/scl enable devtoolset-7 rh-python36 "bash -c \'cmake3 -DLIEF_PYTHON_API=ON -DLIEF_DOC=OFF -DLIEF_EXAMPLES=OFF -DCMAKE_BUILD_TYPE=Release -DPYTHON_VERSION=3.6\'"',
        require   => Exec['ensure build dir'],
        subscribe => Vcsrepo["${misp::install_dir}/app/files/scripts/lief"];

      'compile LIEF':
        command   => '/usr/bin/make -j$(nproc)',
        subscribe => Exec['set up LIEF build'];

      'install LIEF':
        path      => [ "${misp::venv_dir}/bin" ],
        command   => 'python3 setup.py install',
        subscribe => Exec['compile LIEF'],
        require   => Exec['Create virtualenv'];
    }
  }

  exec {
    default:
      command => '/usr/bin/git config core.filemode false && python3 setup.py install',
      path    => ["${misp::venv_dir}/bin", '/usr/bin', '/bin'],
      umask   => '0022',
      require => Exec['Create virtualenv'];

    'python-cybox config':
      cwd       => "${misp::install_dir}/app/files/scripts/python-cybox/",
      unless    => 'pip freeze | /bin/grep cybox',
      subscribe => Vcsrepo["${misp::install_dir}/app/files/scripts/python-cybox"];

    'python-stix config':
      cwd       => "${misp::install_dir}/app/files/scripts/python-stix/",
      unless    => 'pip freeze | /bin/grep stix',
      subscribe => Vcsrepo["${misp::install_dir}/app/files/scripts/python-stix"];

    'mixbox config':
      cwd       => "${misp::install_dir}/app/files/scripts/mixbox/",
      unless    => 'pip freeze | /bin/grep mixbox',
      subscribe => Vcsrepo["${misp::install_dir}/app/files/scripts/mixbox"];

    'python-maec config':
      cwd       => "${misp::install_dir}/app/files/scripts/python-maec/",
      unless    => 'pip freeze | /bin/grep maec',
      subscribe => Vcsrepo["${misp::install_dir}/app/files/scripts/python-maec"];

    'pydeep build':
      command   => 'python3 setup.py build && python3 setup.py install',
      cwd       => "${misp::install_dir}/app/files/scripts/pydeep/",
      unless    => 'pip freeze | /bin/grep pydeep',
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
