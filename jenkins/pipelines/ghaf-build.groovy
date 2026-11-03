@Library('ghafInfra') _

properties([
  buildDiscarder(logRotator(numToKeepStr: '10')),
  disableConcurrentBuilds(),
  parameters([
    string(name: 'REPO_URL', defaultValue: 'https://github.com/tiiuae/ghaf/', description: 'Ghaf repository URL'),
    string(name: 'GITREF', defaultValue: 'main', description: 'Branch, tag, or commit to build'),
    booleanParam(name: 'RELOAD_ONLY', defaultValue: false, description: 'Refresh job parameters without building'),
  ]),
])

// Jobs reload on startup by default; refresh parameters without starting a build.
if (params.RELOAD_ONLY?.toString()?.toBoolean()) {
  echo 'Reloaded pipeline parameters'
  return
}

// Add or change target maps here. This example builds documentation without
// image processing, signing, SBOM generation, publishing, or hardware tests.
def targets = [
  [target: 'packages.x86_64-linux.doc', no_image: true, provenance: false, sbom: false],
]

def builds
try {
  node('built-in') {
    dir(artifactSupport.controller_workdir()) {
      stage('Checkout') {
        checkoutUtils.checkout_remote_ref(params.REPO_URL, params.GITREF)
      }
      stage('Prepare targets') {
        builds = pipelineExecution.create_pipeline(
          targets,
          null, // No default hardware test host.
          null, // Let the library derive the flake reference from the checkout.
          [source_vsa: false],
        )
      }
    }
  }
  // The library acquires controller executors for each target. Release the
  // checkout executor before running these branches to avoid executor starvation.
  stage('Build targets') {
    parallel builds
  }
} finally {
  artifactSupport.clean_controller_workdir()
}
