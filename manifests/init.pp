class icinga_build {
  contain ::jenkins
  contain ::jenkins::cli_helper

  contain ::icinga_build::scripts

  create_resources('icinga_build::job', hiera_hash('jenkins::job', {}))
  create_resources('jenkins::plugin', hiera_hash('jenkins::plugin', {}))
}
