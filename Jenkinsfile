def name = 'openapi_first'
def app
def version

node {
  checkout scm
  stage('Build') {
    app = docker.build("quay.io/invisionag/${name}", "--pull .")
  }

  stage('Test') {
    app.inside {
      sh "bundle exec rake"
    }
  }

  if (env.BRANCH_NAME == 'master') {
    stage('Deploy') {
      app.inside("-u 0:0") {
        version = sh (
          returnStdout: true,
          script: "bundle exec rake version"
        ).trim()
        sh "set +x;curl --fail -F 'file=@/code/pkg/${name}-${version}.gem' https://gems.ivx.cloud/upload"
      }
      node {
        sh "github-release-wrapper release --user ivx --repo ${name} --tag v${version} --name v${version}"
      }
    }
  }
}
