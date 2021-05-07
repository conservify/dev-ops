def call(Map parameters) {
	try {
		stage ('terraform env') {
			if (!fileExists('deploy-${parameters.env}.json')) {
				withCredentials([file(credentialsId: "terraform.tfvars.json", variable: 'TERRAFORM_VARS_JSON')]) {
					withAWS(credentials: 'aws-default', region: 'us-east-1') {
						dir ('dev-ops') {
							git url: 'https://github.com/conservify/dev-ops.git'
							sh "mv -f $TERRAFORM_VARS_JSON terraform"
							sh "cd terraform && TF_IN_AUTOMATION=true TF_CLI_ARGS='-no-color' make env-all"
							sh "mv terraform/build/deploy*.json ../"
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
