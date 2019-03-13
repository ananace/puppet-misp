class misp::service inherits misp {

  require '::misp::config'

  file_line {
    default:
      path   => "/etc/opt/rh/rh-${misp::php_version}/php-fpm.d/www.conf",
      notify => Service["rh-${misp::php_version}-php-fpm"];

    'php-fpm enable rh-python36':
      path => "/etc/opt/rh/rh-${misp::php_version}/sysconfig/php-fpm",
      line => 'source scl_source enable rh-python36';

    'php-fpm no clear_env':
      line  => 'clear_env = no',
      match => '^[; ]*clear_env';

    'php-fpm env[PATH]':
      line  => "env[PATH] = /opt/rh/rh-${misp::php_version}/root/usr/bin:/opt/rh/rh-${misp::php_version}/root/usr/sbin:/opt/rh/rh-python36/root/usr/bin",
      match => '^env[PATH] =';

    'php-fpm env[LD_LIBRARY_PATH]':
      line  => "env[LD_LIBRARY_PATH] = /opt/rh/rh-${misp::php_version}/root/usr/lib64:/opt/rh/rh-python36/root/usr/lib64",
      match => '^env[LD_LIBRARY_PATH] =';

    'php-fpm env[MANPATH]':
      line  => "env[MANPATH] = /opt/rh/rh-${misp::php_version}/root/usr/share/man:/opt/rh/rh-python36/root/usr/share/man",
      match => '^env[MANPATH] =';

    'php-fpm env[PKG_CONFIG_PATH]':
      line  => 'env[PKG_CONFIG_PATH] = /opt/rh/rh-python36/root/usr/lib64/pkgconfig',
      match => '^env[PKG_CONFIG_PATH] =';

    'php-fpm env[XDG_DATA_DIRS]':
      line  => 'env[XDG_DATA_DIRS] = /opt/rh/rh-python36/root/usr/share',
      match => '^env[XDG_DATA_DIRS] =';
  }

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
      notify         => Service['misp-workers'],
    }
  }

  file { '/etc/systemd/system/misp-workers.service':
    ensure  => file,
    content => epp('misp/misp-workers.service.epp', {
        install_dir => $misp::install_dir,
        user        => $misp::default_user,
        group       => $misp::default_group,
        php_version => $misp::php_version,
        services    => [$misp::mariadb_service, 'redis'],
        scls        => [$misp::mariadb_scl],
    }),
    notify  => Service['misp-workers'],
  }
  service { 'misp-workers':
    ensure    => running,
    enable    => true,
    subscribe => Exec['CakeResque install'],
  }
}
