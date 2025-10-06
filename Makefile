
.PHONY: apply sketch .make.inventory-macs.txt.asc

ANSIBLE_INVENTORY = inventory.sh

COMPOSE_RUN = docker compose run --rm
COMPOSE_RUN_PRIVILEGED = $(COMPOSE_RUN) -u root:root

export ANSIBLE_INVENTORY

.make.inventory-macs.txt.asc:
	gpg -r 0x4F212E8A056A0CCC --armor --encrypt-files inventory-macs.txt

inventory-macs.txt: inventory-macs.txt.asc
	gpg --decrypt $< > $@

files/darc/%.eps: files/DARC_Logo_und_Raute.zip # https://www.darc.de/presse/downloads/#c154010
	$(COMPOSE_RUN) unzip -o $< -d files/darc

files/darc/%.svg: files/darc/%.eps
	$(COMPOSE_RUN) eps2svg $< $@

files/wallpaper.png: files/darc/DARC_Raute.svg
	$(COMPOSE_RUN) convert -resize 500x500 -background none $< -background "#231F20" -gravity center -extent 1920x1080 -font "/usr/share/fonts/truetype/roboto/unhinted/RobotoCondensed-Bold.ttf" -pointsize 36 -fill white -draw "text 0,300 'L05'" $@

setup: 00-setup.yaml $(ANSIBLE_INVENTORY) files/wallpaper.png
	ansible-playbook $<

reset: 01-reset.yaml $(ANSIBLE_INVENTORY)
	ansible-playbook $<

applications: 10-applications.yaml $(ANSIBLE_INVENTORY)
	ansible-playbook $<

course: 20-course.yaml $(ANSIBLE_INVENTORY)
	ansible-playbook $<

sketch: 21-course-sketches.yaml $(ANSIBLE_INVENTORY)
	ansible-playbook $< -e 'sketch_course="$(COURSE)"'

course-files: course sketch

.PHONY: apply
apply: setup applications course-files
