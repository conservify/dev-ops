def call(Map parameters) {
	try {
		stage ('terraform env') {
			if (!fileExists('deploy-${parameters.env}.json')) {
				withCredentials([file(credentialsId: "terraform.tfvars.json", variable: 'TERRAFORM_VARS_JSON')]) {
					withAWS(credentials: 'AWS Default', region: 'us-east-1') {
						dir ('dev-ops') {
							git url: 'https://github.com/conservify/dev-ops.git'
							sh "mv -f $TERRAFORM_VARS_JSON terraform"
							sh "cd terraform/fk && TF_IN_AUTOMATION=true TF_CLI_ARGS='-no-color' make ${parameters.env} env"
							sh "mv terraform/fk/deploy.json ../deploy-${parameters.env}.json"
						}
					}
				}
			}
			else {
				echo 'have deploy-${parameters.env}.json, skipping generation'
			}

			return readJSON(file: "deploy-${parameters.env}.json")
		}
	}
	catch (Exception e) {
		throw e
	}
}
