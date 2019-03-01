class misp::config inherits misp {

  require '::misp::install'

  # Apache permissions

  file { "${misp::install_dir}/app/Plugin/CakeResque/Config/config.php":
    ensure    => file,
    owner     => $misp::default_high_user,
    group     => $misp::default_high_group,
    source    => "file://${misp::install_dir}/INSTALL/setup/config.php",
    subscribe => Exec['CakeResque require'],
  }

  exec {'Directory permissions':
    command     => "/usr/bin/chown -R ${misp::default_high_user}:${misp::default_high_group} ${misp::install_dir} && /usr/bin/find ${misp::install_dir} -type d -exec /usr/bin/chmod g=rx {} \\; && /usr/bin/chmod -R g+r,o= ${misp::install_dir}",
    refreshonly => true,
    require     => File["${misp::install_dir}/app/Plugin/CakeResque/Config/config.php"],
    subscribe   => Exec['CakeResque require'],
  }

  file {"${misp::install_dir}/app/files" :
    ensure    => directory,
    owner     => $misp::default_user,
    group     => $misp::default_group,
    seltype   => 'httpd_sys_rw_content_t',
    recurse   => true,
    subscribe => Exec['Directory permissions'],
    notify    => File["${misp::install_dir}/app/files/terms","${misp::install_dir}/app/files/scripts/tmp"],
  }

  file {["${misp::install_dir}/app/files/terms","${misp::install_dir}/app/files/scripts/tmp"] :
    ensure  => directory,
    owner   => $misp::default_user,
    group   => $misp::default_group,
    seltype => 'httpd_sys_rw_content_t',
    recurse => false,
  }

  file {"${misp::install_dir}/app/Plugin/CakeResque/tmp" :
    ensure    => directory,
    owner     => $misp::default_user,
    group     => $misp::default_group,
    seltype   => 'httpd_sys_rw_content_t',
    recurse   => false,
    subscribe => Exec['Directory permissions'],
  }

  file {["${misp::install_dir}/app/tmp","${misp::install_dir}/app/webroot/img/orgs", "${misp::install_dir}/app/webroot/img/custom"] :
    ensure    => directory,
    owner     => $misp::default_user,
    group     => $misp::default_group,
    mode      => '0750',
    recurse   => true,
    seltype   => 'httpd_sys_rw_content_t',
    subscribe => Exec['Directory permissions'],
    notify    => File["${misp::install_dir}/app/tmp/logs/"],#Comment for logrotate usage
  }

  #selinux::fcontext{'tmp_fcontext' :
  #  pathname  => '/var/www/MISP/app/tmp/logs(/.*)?',
  #  filemode  => 'a',
  #  context   => 'httpd_log_t' ,
  #  subscribe => File["${misp::install_dir}/app/tmp","${misp::install_dir}/app/webroot/img/orgs", "${misp::install_dir}/app/webroot/img/custom"] ,
  #  notify    => File["${misp::install_dir}/app/tmp/logs/"],
  #}

  file {"${misp::install_dir}/app/tmp/logs/" :
    ensure  => directory,
    mode    => '0750',
    owner   => $misp::default_user,
    group   => $misp::default_group,
    recurse => true,
    #seltype => 'httpd_log_t', #Uncomment for logrotate usage
    seltype => 'httpd_sys_rw_content_t',
  }

  file { "${misp::config_dir}/bootstrap.php":
    ensure    => file,
    owner     => $misp::default_high_user,
    group     => $misp::default_high_group,
    content   => template('misp/bootstrap.php.erb'),
    subscribe => Exec['Directory permissions'],
  }

  file { "${misp::config_dir}/core.php":
    ensure    => file,
    owner     => $misp::default_high_user,
    group     => $misp::default_high_group,
    content   => template('misp/core.php.erb'),
    subscribe => Exec['Directory permissions'],
  }

  file{"${misp::config_dir}/database.php":
    ensure    => file,
    owner     => $misp::default_high_user,
    group     => $misp::default_high_group,
    mode      => '0640',
    content   => template('misp/database.php.erb'),
    subscribe => Exec['Directory permissions'],
  }

  $config_contents = epp('misp/config.php.epp', {
      'debug'                                       => $debug,
      'site_admin_debug'                            => $site_admin_debug,
      'security_level'                              => $security_level,
      'salt'                                        => $salt,
      'cipherseed'                                  => $cipherseed,
      'auth_method'                                 => $auth_method,
      'password_policy_length'                      => $password_policy_length,
      'password_policy_complexity'                  => $password_policy_complexity,
      'sanitise_attribute_on_delete'                => $sanitise_attribute_on_delete,
      'require_password_confirmation'               => $require_password_confirmation,
      'hide_organisation_index_from_users'          => $hide_organisation_index_from_users,
      'baseurl'                                     => $baseurl,
      'live'                                        => $live,
      'language'                                    => $language,
      'enable_advanced_correlations'                => $enable_advanced_correlations,
      'uuid'                                        => $uuid,
      'showorg'                                     => $showorg,
      'email'                                       => $email,
      'disable_emailing'                            => $disable_emailing,
      'default_event_distribution'                  => $default_event_distribution,
      'default_attribute_distribution'              => $default_attribute_distribution,
      'default_event_tag_collection'                => $default_event_tag_collection,
      'proposals_block_attributes'                  => $proposals_block_attributes,
      'completely_disable_correlation'              => $completely_disable_correlation,
      'allow_disabling_correlation'                 => $allow_disabling_correlation,
      'redis_host'                                  => $redis_host,
      'redis_port'                                  => $redis_port,
      'redis_database'                              => $redis_database,
      'redis_password'                              => $redis_password,
      'python_bin'                                  => $python_bin,
      'disable_auto_logout'                         => $disable_auto_logout,
      'ssdeep_correlation_threshold'                => $ssdeep_correlation_threshold,
      'max_correlations_per_event'                  => $max_correlations_per_event,
      'disable_cached_exports'                      => $disable_cached_exports,
      'org'                                         => $org,
      'background_jobs'                             => $background_jobs,
      'cached_attachments'                          => $cached_attachments,
      'contact'                                     => $contact,
      'cveurl'                                      => $cveurl,
      'disablerestalert'                            => $disablerestalert,
      'extended_alert_subject'                      => $extended_alert_subject,
      'default_event_threat_level'                  => $default_event_threat_level,
      'tagging'                                     => $tagging,
      'new_user_text'                               => $new_user_text,
      'password_reset_text'                         => $password_reset_text,
      'enable_event_blacklisting'                   => $enable_event_blacklisting,
      'log_client_ip'                               => $log_client_ip,
      'log_auth'                                    => $log_auth,
      'delegation'                                  => $delegation,
      'show_correlations_on_index'                  => $show_correlations_on_index,
      'show_proposals_count_on_index'               => $show_proposals_count_on_index,
      'show_sightings_count_on_index'               => $show_sightings_count_on_index,
      'show_discussions_count_on_index'             => $show_discussions_count_on_index,
      'disable_user_self_management'                => $disable_user_self_management,
      'block_event_alert'                           => $block_event_alert,
      'block_event_alert_tag'                       => $block_event_alert_tag,
      'block_old_event_alert'                       => $block_old_event_alert,
      'block_old_event_alert_age'                   => $block_old_event_alert_age,
      'tmpdir'                                      => $tmpdir,
      'incoming_tags_disabled_by_default'           => $incoming_tags_disabled_by_default,
      'deadlock_avoidance'                          => $deadlock_avoidance,
      'maintenance_message'                         => $maintenance_message,
      'footermidleft'                               => $footermidleft,
      'footermidright'                              => $footermidright,
      'footer_logo'                                 => $footer_logo,
      'home_logo'                                   => $home_logo,
      'main_logo'                                   => $main_logo,
      'threatlevel_in_email_subject'                => $threatlevel_in_email_subject,
      'email_subject_tlp_string'                    => $email_subject_tlp_string,
      'email_subject_tag'                           => $email_subject_tag,
      'email_subject_include_tag_name'              => $email_subject_include_tag_name,
      'attachments_dir'                             => $attachments_dir,
      'download_attachments_on_load'                => $download_attachments_on_load,
      'full_tags_on_event_index'                    => $full_tags_on_event_index,
      'welcome_text_top'                            => $welcome_text_top,
      'welcome_text_bottom'                         => $welcome_text_bottom,
      'welcome_logo'                                => $welcome_logo,
      'welcome_logo2'                               => $welcome_logo2,
      'title_text'                                  => $title_text,
      'take_ownership_xml_import'                   => $take_ownership_xml_import,
      'terms_download'                              => $terms_download,
      'terms_file'                                  => $terms_file,
      'showorgalternate'                            => $showorgalternate,
      'unpublishedprivate'                          => $unpublishedprivate,
      'custom_css'                                  => $custom_css,
      'event_view_filter_fields'                    => $event_view_filter_fields,
      'manage_workers'                              => $manage_workers,
      'gpg_onlyencrypted'                           => $gpg_onlyencrypted,
      'gpg_email'                                   => $gpg_email,
      'gpg_homedir'                                 => $gpg_homedir,
      'gpg_password'                                => $gpg_password,
      'gpg_binary'                                  => $gpg_binary,
      'gpg_bodyonlyencrypted'                       => $gpg_bodyonlyencrypted,
      'gpg_sign'                                    => $gpg_sign,
      'smime_enabled'                               => $smime_enabled,
      'smime_email'                                 => $smime_email,
      'smime_cert_public_sign'                      => $smime_cert_public_sign,
      'smime_key_sign'                              => $smime_key_sign,
      'smime_password'                              => $smime_password,
      'proxy_host'                                  => $proxy_host,
      'proxy_port'                                  => $proxy_port,
      'proxy_method'                                => $proxy_method,
      'proxy_user'                                  => $proxy_user,
      'proxy_password'                              => $proxy_password,
      'security_syslog'                             => $security_syslog,
      'security_allow_unsafe_apikey_named_param'    => $security_allow_unsafe_apikey_named_param,
      'security_require_password_confirmation'      => $security_require_password_confirmation,
      'security_sanitise_attribute_on_delete'       => $security_sanitise_attribute_on_delete,
      'security_hide_organisation_index_from_users' => $security_hide_organisation_index_from_users,
      'security_password_policy_length'             => $security_password_policy_length,
      'security_password_policy_complexity'         => $security_password_policy_complexity,
      'secure_auth_amount'                          => $secure_auth_amount,
      'secure_auth_expire'                          => $secure_auth_expire,
      'session_auto_regenerate'                     => $session_auto_regenerate,
      'session_check_agent'                         => $session_check_agent,
      'session_defaults'                            => $session_defaults,
      'session_timeout'                             => $session_timeout,
      'session_cookie_timeout'                      => $session_cookie_timeout,
  }),
  if $mips::allow_config_changes {
    fail('Not supported at the moment')
  } else {
    file{"${misp::config_dir}/config.php":
      ensure    => file,
      owner     => $misp::default_high_user,
      group     => $misp::default_high_group,
      mode      => '0640',
      content   => $config_contents,
      subscribe => Exec['Directory permissions'],
    }
  }

  if fact('os.selinux.enabled') {
    selboolean { 'httpd redis connection':
      name       => 'httpd_can_network_connect',
      persistent => true,
      value      => 'on',
    }

    Selboolean['httpd redis connection'] ~> Service <| title == $misp::webservername |>
  }

  file{"${misp::install_dir}/app/Console/worker/start.sh":
    owner => $misp::default_high_user,
    group => $misp::default_high_group,
    mode  => '+x',
  }
}
