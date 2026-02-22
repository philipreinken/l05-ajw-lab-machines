
ANSIBLE_EXEC = ansible-playbook
ANSIBLE_VAULT_ENC_EXEC = ansible-vault encrypt
ANSIBLE_VAULT_VIEW_EXEC = ansible-vault view
ANSIBLE_VAULT_EDIT_EXEC = ansible-vault edit

# if the bitwarden is installed, use it to get the vault password; otherwise ask for it interactively
ifeq ($(shell which bw 2>/dev/null),)
ANSIBLE_EXEC += -e @vault.bin --ask-vault-pass
ANSIBLE_VAULT_ENC_EXEC += --ask-vault-pass
ANSIBLE_VAULT_VIEW_EXEC += --ask-vault-pass
ANSIBLE_VAULT_EDIT_EXEC += --ask-vault-pass
else
ANSIBLE_EXEC += -e @vault.bin --vault-password-file=vault-pass-bw.sh
ANSIBLE_VAULT_ENC_EXEC += --vault-password-file=vault-pass-bw.sh
ANSIBLE_VAULT_VIEW_EXEC += --vault-password-file=vault-pass-bw.sh
ANSIBLE_VAULT_EDIT_EXEC += --vault-password-file=vault-pass-bw.sh
endif

ifdef DEBUG
ANSIBLE_EXEC += -vv
endif

ANSIBLE_INVENTORY = inventory.sh
ANSIBLE_HOST_KEY_CHECKING = False
ANSIBLE_DEPS = $(ANSIBLE_INVENTORY) .make.ansible-galaxy-install vault.bin

COMPOSE_RUN = docker compose run --rm
COMPOSE_RUN_PRIVILEGED = $(COMPOSE_RUN) -u root:root

export ANSIBLE_INVENTORY
export ANSIBLE_HOST_KEY_CHECKING
export ANSIBLE_VAULT_FILE

.make.ansible-galaxy-install: requirements.yaml
	ansible-galaxy install -r $<
	touch $@

files/darc/%.eps: files/DARC_Logo_und_Raute.zip # https://www.darc.de/presse/downloads/#c154010
	$(COMPOSE_RUN) unzip -o $< -d files/darc

files/darc/%.svg: files/darc/%.eps
	$(COMPOSE_RUN) eps2svg $< $@

files/wallpaper.png: files/darc/DARC_Raute.svg
	$(COMPOSE_RUN) convert -density 300 -resize 960x960 -background none $< -background "#231F20" -gravity center -extent 3840x2160 -font "/usr/share/fonts/truetype/roboto/unhinted/RobotoCondensed-Bold.ttf" -pointsize 16 -fill white -draw "text 0,500 'L05'" $@

.PHONY: setup
setup: 00-setup.yaml $(ANSIBLE_DEPS) files/wallpaper.png
	$(ANSIBLE_EXEC) $<

.PHONY: reset
reset: 01-reset.yaml $(ANSIBLE_DEPS)
	$(ANSIBLE_EXEC) $<

.PHONY: update
update: 02-update.yaml $(ANSIBLE_DEPS)
	$(ANSIBLE_EXEC) $<

.PHONY: applications
applications: 10-applications.yaml $(ANSIBLE_DEPS)
	$(ANSIBLE_EXEC) $<

.PHONY: course
course: 20-course.yaml $(ANSIBLE_DEPS)
	$(ANSIBLE_EXEC) $<

.PHONY: course-copy-only
course-copy-only: 20-course.yaml $(ANSIBLE_DEPS)
	$(ANSIBLE_EXEC) -v $< -e code_copy_only=true

.PHONY: full
full: setup applications course

.PHONY: shutdown
shutdown: $(ANSIBLE_INVENTORY)
	ansible all -b -m community.general.shutdown

.PHONY: view-vault
view-vault: vault.bin
	$(ANSIBLE_VAULT_VIEW_EXEC) $<

.PHONY: edit-vault
edit-vault: vault.bin
	$(ANSIBLE_VAULT_EDIT_EXEC) $<