
.PHONY: apply sketch .make.inventory-macs.txt.asc awx

COMPOSE_RUN = docker compose run --rm

.make.inventory-macs.txt.asc:
	gpg -r 0x4F212E8A056A0CCC --armor --encrypt-files inventory-macs.txt

.make.awx-admin-password:
	kubectl get secret awx-demo-admin-password -o jsonpath="{.data.password}" | base64 --decode

inventory-macs.txt: inventory-macs.txt.asc
	gpg --decrypt $< > $@

inventory.yaml: inventory.sh inventory-macs.txt
	$(COMPOSE_RUN) bash $< > $@

files/darc/%.eps: files/DARC_Logo_und_Raute.zip # https://www.darc.de/presse/downloads/#c154010
	$(COMPOSE_RUN) unzip -o $< -d files/darc

files/darc/%.svg: files/darc/%.eps
	$(COMPOSE_RUN) eps2svg $< $@

files/wallpaper.png: files/darc/DARC_Raute.svg
	$(COMPOSE_RUN) convert -resize 500x500 -background none $< -background "#231F20" -gravity center -extent 1920x1080 -font "/usr/share/fonts/truetype/roboto/unhinted/RobotoCondensed-Bold.ttf" -pointsize 36 -fill white -draw "text 0,300 'L05'" $@

apply: inventory.yaml playbook.yaml
	ansible-playbook -i inventory.yaml playbook.yaml

sketch-init: inventory.yaml sketch-init.yaml
	ansible-playbook -i inventory.yaml sketch-init.yaml -e git_init="true" -e sketch_init="true" -e 'sketch_course="$(COURSE)"'

sketch: inventory.yaml sketch-init.yaml
	ansible-playbook --verbose -i inventory.yaml sketch-init.yaml -e git_init="false" -e sketch_init="false" -e 'sketch_course="$(COURSE)"'

kind: kind.config
	kind get clusters | grep -q 'kind' || kind create cluster --config=$<
	kubectl cluster-info --context kind-kind
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

awx: kind
	kubectl create namespace awx
	kubectl config set-context --current --namespace=awx
	helm repo add awx-operator https://ansible-community.github.io/awx-operator-helm/
	helm repo update
	helm install my-awx-operator awx-operator/awx-operator
	kubectl create -f awx-cr.yaml