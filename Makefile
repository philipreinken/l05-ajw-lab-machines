
ANSIBLE_INVENTORY = inventory.sh
ANSIBLE_HOST_KEY_CHECKING = False

COMPOSE_RUN = docker compose run --rm
COMPOSE_RUN_PRIVILEGED = $(COMPOSE_RUN) -u root:root

export ANSIBLE_INVENTORY
export ANSIBLE_HOST_KEY_CHECKING

.PHONY: .make.inventory-macs.txt.asc
.make.inventory-macs.txt.asc:
	gpg -r 0x4F212E8A056A0CCC --armor --encrypt-files inventory-macs.txt

inventory-macs.txt: inventory-macs.txt.asc
	gpg --decrypt $< > $@

files/darc/%.eps: files/DARC_Logo_und_Raute.zip # https://www.darc.de/presse/downloads/#c154010
	$(COMPOSE_RUN) unzip -o $< -d files/darc

files/darc/%.svg: files/darc/%.eps
	$(COMPOSE_RUN) eps2svg $< $@

files/wallpaper.png: files/darc/DARC_Raute.svg
	$(COMPOSE_RUN) convert -density 300 -resize 960x960 -background none $< -background "#231F20" -gravity center -extent 3840x2160 -font "/usr/share/fonts/truetype/roboto/unhinted/RobotoCondensed-Bold.ttf" -pointsize 16 -fill white -draw "text 0,500 'L05'" $@

.PHONY: setup
setup: 00-setup.yaml $(ANSIBLE_INVENTORY) files/wallpaper.png
	ansible-playbook $<

.PHONY: reset
reset: 01-reset.yaml $(ANSIBLE_INVENTORY)
	ansible-playbook $<

.PHONY: applications
applications: 10-applications.yaml $(ANSIBLE_INVENTORY)
	ansible-playbook $<

.PHONY: course
course: 20-course.yaml $(ANSIBLE_INVENTORY)
	ansible-playbook -v $<

.PHONY: course-copy-only
course-copy-only: 20-course.yaml $(ANSIBLE_INVENTORY)
	ansible-playbook -v $< -e code_copy_only=true

.PHONY: full
full: setup applications course

.PHONY: shutdown
shutdown: $(ANSIBLE_INVENTORY)
	ansible all -b -m community.general.shutdown
