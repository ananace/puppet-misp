class misp::service inherits misp {

  require '::misp::config'

  service { "rh-${misp::php_version}-php-fpm":
    ensure => 'running',
    enable => true,
  }

  if $misp::manage_haveged {
    service { 'haveged':
      ensure => 'running',
      enable => true,
    }
  }

  if $misp::redis_server {
    # redis module needed when using password for ease of set up
    class { '::redis':
      service_ensure => true,
      service_enable => true,
      bind           => $misp::redis_host,
      requirepass    => $misp::redis_password,
      port           => $misp::redis_port,
      notify         => Exec['start bg workers', 'restart bg workers'],
    }
  }

  exec {'start bg workers':
    command => "/usr/bin/su -s /bin/bash ${misp::default_user} -c '/usr/bin/scl enable rh-${misp::php_version} ${misp::install_dir}/app/Console/worker/start.sh'",
    unless  => "/usr/bin/su -s /bin/bash ${misp::default_user} -c '/usr/bin/scl enable rh-${misp::php_version} ${misp::install_dir}/app/Console/worker/status.sh'",
    user    => $misp::default_high_user,
    group   => $misp::default_high_group,
  }

  exec {'restart bg workers':
    command     => "/usr/bin/su -s /bin/bash ${misp::default_user} -c '/usr/bin/scl enable rh-${misp::php_version} ${misp::install_dir}/app/Console/worker/start.sh'",
    user        => $misp::default_high_user,
    group       => $misp::default_high_group,
    refreshonly => true,
    subscribe   => Exec['CakeResque install'],
  }
}
