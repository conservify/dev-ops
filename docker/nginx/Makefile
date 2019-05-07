build:
	docker build --rm -t nginx-rproxy .

test:
	docker run --name rproxy \
		--rm \
		-v /home/jenkins/artifacts:/var/lib/jenkins_artifacts \
		-p 80:80 -p 443:443 \
		--link jenkins \
		--link nexus \
		--link fk-landing \
		--add-host="parent:172.17.0.1" \
		nginx-rproxy

run:
	docker run --name rproxy \
		-d --restart always \
		-v /home/jenkins/artifacts:/var/lib/jenkins_artifacts \
		-p 80:80 -p 443:443 \
		--link logs \
		--link jenkins \
		--link nexus \
		--link fk-landing \
		--add-host="parent:172.17.0.1" \
		nginx-rproxy

backup:
	sudo tar cjf letsencrypt-`date +"%Y-%m-%d_%H-%M-%S"`.tar.bz2 letsencrypt-*
