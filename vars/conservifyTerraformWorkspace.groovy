def call(Map parameters) {
	try {
		stage ('terraform env') {
			if (!fileExists('deploy-${parameters.env}.env')) {
				withCredentials([file(credentialsId: "terraform.tfvars.json", variable: 'TERRAFORM_VARS_JSON')]) {
					withAWS(credentials: 'AWS Default', region: 'us-east-1') {
						dir ('dev-ops') {
							git url: 'https://github.com/conservify/dev-ops.git'
							sh "mv -f $TERRAFORM_VARS_JSON terraform"
							sh "cd terraform && TF_IN_AUTOMATION=true TF_CLI_ARGS='-no-color' make ${parameters.env} env"
							sh "mv terraform/deploy.env ../deploy-${parameters.env}.env"
						}
					}
				}
			}
			else {
				echo 'have deploy-${parameters.env}.env, skipping generation'
			}

			return readProperties(file: "deploy-${parameters.env}.env")
		}
	}
	catch (Exception e) {
		throw e
	}
}
