
.PHONY: apply inventory.yaml

COMPOSE_RUN = docker compose run --rm

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

apply: inventory.yaml
	ansible-playbook -i inventory.yaml playbook.yaml
