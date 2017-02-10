define icinga_build::pipeline (
  $control_repo,
  $product        = undef, # part of namevar
  $target         = undef, # part of namevar
  $control_branch = 'snapshot',
  $description    = undef,
  $matrix_deb     = { },
  $matrix_rpm     = { },
  $arch           = $icinga_build::pipeline::defaults::arch,
  $docker_image   = $icinga_build::pipeline::defaults::docker_image,
  $jenkins_label  = $icinga_build::pipeline::defaults::jenkins_label,
  $views_hash     = $icinga_build::pipeline::defaults::views_hash,
) {
  if $views_hash { validate_hash($views_hash) }

  if $product and $target {
    $_product = $product
    $_target = $target
  } elsif $name =~ /^([\w\d\._]+)-([\w\d\._]+)$/ {
    $_product = $1
    $_target = $2
  } else {
    fail("Can not parse product/target from name: ${name}")
  }

  unless $arch and $docker_image and $jenkins_label {
    fail('Please ensure to configure icinga_build::pipeline::defaults, or add the parameters directly')
  }

  validate_re($_product, '^[\w_\.\-\d]+$')
  validate_re($_target, '^[\w_\.\-\d]+$')

  # define folder
  icinga_build::folder { $title:
    ensure      => present,
    description => "Icinga build pipeline for ${_product} with release target ${_target}\n\n${description}",
    views_xml   => template('icinga_build/views/pipeline.xml.erb'),
    icon        => 'aggregate-status',
  }

  # TODO: what to do with target?

  # create matrizes
  create_resources('icinga_build::pipeline::deb', prefix($matrix_deb, "${title}-"), {
    product        => $_product,
    pipeline       => $title,
    control_repo   => $control_repo,
    control_branch => $control_branch,
    arch           => $arch,
    docker_image   => $docker_image,
    jenkins_label  => $jenkins_label,
    tag            => $title,
  })
  # TODO: implement rpm
  create_resources('icinga_build::pipeline::rpm', prefix($matrix_rpm, "${title}-"), {
    product        => $_product,
    pipeline       => $title,
    control_repo   => $control_repo,
    control_branch => $control_branch,
    arch           => $arch,
    docker_image   => $docker_image,
    jenkins_label  => $jenkins_label,
    tag            => $title,
  })

  # TODO: this is a dep cycle
  #Icinga_build::Pipeline::Deb <| tag == $title |> -> Icinga_build::Pipeline[$title]
}
